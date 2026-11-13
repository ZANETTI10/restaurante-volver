// =====================================================================
//  Restaurante Volver · Edge Function "usuarios"
//  Única vía para crear y administrar usuarios (sin correo).
//  Cada usuario se guarda en Supabase Auth como <usuario>@usuarios.volver.app
//  (dominio interno: nunca se envían correos).
//
//  Acciones (POST JSON {accion, ...}):
//   - inicial     {usuario, nombre, clave}         Crea el primer Administrador TI. Solo si no hay perfiles.
//   - listar      {}                                Lista los perfiles.                    (rol ti)
//   - crear       {usuario, nombre, rol, clave}     Crea usuario con contraseña temporal.  (rol ti)
//   - actualizar  {user_id, nombre, rol}            Cambia nombre o rol.                   (rol ti)
//   - activo      {user_id, activo}                 Activa / desactiva (bloquea el ingreso). (rol ti)
//   - clave       {user_id, clave}                  Restablece contraseña temporal.        (rol ti)
//
//  Variables (las pone Supabase automáticamente): SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY
//  Desplegar: supabase functions deploy usuarios   (o desde el panel de Supabase)
// =====================================================================
import { createClient } from "npm:@supabase/supabase-js@2.45.4";

const DOMINIO = "usuarios.volver.app";
const ROLES = ["reservas", "caja", "tesoreria", "admin", "ti"];
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const resp = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const normUsuario = (u: string) =>
  String(u || "").toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, "").trim()
    .replace(/\s+/g, ".").replace(/[^a-z0-9._-]/g, "");
const claveValida = (c: string) => typeof c === "string" && c.length >= 8 && /[a-zA-Z]/.test(c) && /\d/.test(c);

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return resp({ error: "Método no permitido" }, 405);

  const url = Deno.env.get("SUPABASE_URL")!;
  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false } });
  let body: Record<string, unknown>;
  try { body = await req.json(); } catch { return resp({ error: "Solicitud no válida" }, 400); }
  const accion = String(body.accion || "");

  // ---- Primer usuario (bootstrap): solo cuando no existe ningún perfil ----
  if (accion === "inicial") {
    const { count } = await admin.from("perfiles").select("user_id", { count: "exact", head: true });
    if ((count ?? 0) > 0) return resp({ error: "Ya existen usuarios; usa la sección TI de la aplicación." }, 403);
    const usuario = normUsuario(String(body.usuario));
    if (usuario.length < 3 || !claveValida(String(body.clave))) return resp({ error: "Usuario o contraseña no válidos" }, 400);
    const { data, error } = await admin.auth.admin.createUser({
      email: `${usuario}@${DOMINIO}`, password: String(body.clave), email_confirm: true, user_metadata: { usuario },
    });
    if (error) return resp({ error: error.message }, 400);
    const { error: e2 } = await admin.from("perfiles").insert({
      user_id: data.user.id, usuario, nombre: String(body.nombre || "Administrador"), rol: "ti", debe_cambiar: true,
    });
    if (e2) return resp({ error: e2.message }, 400);
    return resp({ ok: true, usuario });
  }

  // ---- Las demás acciones exigen sesión de un usuario TI activo ----
  const jwt = (req.headers.get("Authorization") || "").replace("Bearer ", "");
  const { data: quien } = await admin.auth.getUser(jwt);
  if (!quien?.user) return resp({ error: "Sesión no válida" }, 401);
  const { data: yo } = await admin.from("perfiles").select("rol, activo").eq("user_id", quien.user.id).maybeSingle();
  if (!yo || !yo.activo || yo.rol !== "ti") return resp({ error: "Solo el Administrador (TI) puede administrar usuarios" }, 403);

  const auditar = (registro_id: string, accionTxt: string, despues: unknown) =>
    admin.from("auditoria").insert({ tabla: "perfiles", registro_id, accion: accionTxt, usuario: quien.user!.id, despues });

  if (accion === "listar") {
    const { data, error } = await admin.from("perfiles").select("user_id, usuario, nombre, rol, activo, debe_cambiar, creado").order("usuario");
    if (error) return resp({ error: error.message }, 400);
    return resp({ usuarios: data });
  }

  if (accion === "crear") {
    const usuario = normUsuario(String(body.usuario));
    const rol = String(body.rol);
    if (usuario.length < 3) return resp({ error: "El usuario debe tener mínimo 3 caracteres" }, 400);
    if (!ROLES.includes(rol)) return resp({ error: "Rol no válido" }, 400);
    if (!claveValida(String(body.clave))) return resp({ error: "Contraseña temporal no válida" }, 400);
    const { data: existe } = await admin.from("perfiles").select("user_id").eq("usuario", usuario).maybeSingle();
    if (existe) return resp({ error: "Ese usuario ya existe" }, 409);
    const { data, error } = await admin.auth.admin.createUser({
      email: `${usuario}@${DOMINIO}`, password: String(body.clave), email_confirm: true, user_metadata: { usuario },
    });
    if (error) return resp({ error: error.message.includes("already") ? "Ese usuario ya existe" : error.message }, 400);
    const perfil = { user_id: data.user.id, usuario, nombre: String(body.nombre || usuario).slice(0, 80), rol, debe_cambiar: true };
    const { error: e2 } = await admin.from("perfiles").insert(perfil);
    if (e2) { await admin.auth.admin.deleteUser(data.user.id); return resp({ error: e2.message }, 400); }
    await auditar(data.user.id, "CREAR USUARIO", { usuario, rol });
    return resp({ ok: true });
  }

  const user_id = String(body.user_id || "");
  if (!user_id) return resp({ error: "Falta el usuario" }, 400);

  if (accion === "actualizar") {
    const rol = String(body.rol);
    if (!ROLES.includes(rol)) return resp({ error: "Rol no válido" }, 400);
    if (user_id === quien.user.id && rol !== "ti") return resp({ error: "No puedes quitarte tu propio rol de TI" }, 400);
    const { error } = await admin.from("perfiles").update({ nombre: String(body.nombre || "").slice(0, 80), rol }).eq("user_id", user_id);
    if (error) return resp({ error: error.message }, 400);
    await auditar(user_id, "ACTUALIZAR USUARIO", { nombre: body.nombre, rol });
    return resp({ ok: true });
  }

  if (accion === "activo") {
    if (user_id === quien.user.id) return resp({ error: "No puedes desactivar tu propio usuario" }, 400);
    const activo = Boolean(body.activo);
    const { error } = await admin.from("perfiles").update({ activo }).eq("user_id", user_id);
    if (error) return resp({ error: error.message }, 400);
    await admin.auth.admin.updateUserById(user_id, { ban_duration: activo ? "none" : "876000h" });
    await auditar(user_id, activo ? "ACTIVAR USUARIO" : "DESACTIVAR USUARIO", { activo });
    return resp({ ok: true });
  }

  if (accion === "clave") {
    if (!claveValida(String(body.clave))) return resp({ error: "Contraseña temporal no válida" }, 400);
    const { error } = await admin.auth.admin.updateUserById(user_id, { password: String(body.clave) });
    if (error) return resp({ error: error.message }, 400);
    await admin.from("perfiles").update({ debe_cambiar: true }).eq("user_id", user_id);
    await auditar(user_id, "RESTABLECER CONTRASEÑA", {});
    return resp({ ok: true });
  }

  return resp({ error: "Acción no reconocida" }, 400);
});
