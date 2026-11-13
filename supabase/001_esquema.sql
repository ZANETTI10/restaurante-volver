-- =====================================================================
--  Restaurante Volver · Esquema de base de datos (Supabase / PostgreSQL)
--  Versión 001 · noviembre 2026 · Soporte TI
--
--  Cómo aplicarlo: Supabase → SQL Editor → pegar todo este archivo → Run.
--  Es idempotente en lo posible (create if not exists / or replace).
--
--  Diseño:
--   * Una tabla por módulo con (id, data jsonb). La app guarda cada registro
--     como un documento JSON; así se puede evolucionar sin migraciones
--     frecuentes. Las vistas al final exponen columnas para reportes.
--   * perfiles: une cada usuario de Supabase Auth con su área (rol).
--   * RLS: solo usuarios con perfil ACTIVO leen y escriben. Borrar: solo Gerencia.
--   * auditoria: cada cambio queda registrado (quién, cuándo, antes/después).
--   * Formulario público: los clientes envían sus datos por la función
--     registrar_cliente(); no pueden leer nada.
-- =====================================================================

-- ---------- 1. Perfiles y roles ----------
create table if not exists public.perfiles (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  nombre     text not null,
  rol        text not null check (rol in ('reservas','caja','tesoreria','admin')),
  activo     boolean not null default true,
  creado     timestamptz not null default now()
);
comment on table public.perfiles is 'Usuarios del sistema y su área: reservas, caja, tesoreria (tesorería y contabilidad), admin (gerencia / administración).';

create or replace function public.es_activo() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.perfiles where user_id = auth.uid() and activo);
$$;

create or replace function public.rol_actual() returns text
language sql stable security definer set search_path = public as $$
  select rol from public.perfiles where user_id = auth.uid() and activo;
$$;

alter table public.perfiles enable row level security;
drop policy if exists perfiles_ver on public.perfiles;
create policy perfiles_ver on public.perfiles for select
  using (user_id = auth.uid() or public.rol_actual() = 'admin');
drop policy if exists perfiles_admin on public.perfiles;
create policy perfiles_admin on public.perfiles for update
  using (public.rol_actual() = 'admin') with check (public.rol_actual() = 'admin');

-- ---------- 2. Tablas de la operación ----------
do $$
declare t text;
begin
  foreach t in array array['clientes','reservas','anticipos','mesas','bonos','cartera'] loop
    execute format($f$
      create table if not exists public.%1$I (
        id          text primary key,
        data        jsonb not null default '{}'::jsonb,
        created_at  timestamptz not null default now(),
        updated_at  timestamptz not null default now(),
        updated_by  uuid default auth.uid()
      );
      alter table public.%1$I enable row level security;
      drop policy if exists %1$s_leer on public.%1$I;
      create policy %1$s_leer on public.%1$I for select using (public.es_activo());
      drop policy if exists %1$s_crear on public.%1$I;
      create policy %1$s_crear on public.%1$I for insert with check (public.es_activo());
      drop policy if exists %1$s_editar on public.%1$I;
      create policy %1$s_editar on public.%1$I for update using (public.es_activo()) with check (public.es_activo());
      drop policy if exists %1$s_borrar on public.%1$I;
      create policy %1$s_borrar on public.%1$I for delete using (public.rol_actual() = 'admin');
    $f$, t);
  end loop;
end $$;

-- Las cortesías (bonos regalados) solo las crea Gerencia / Administración
drop policy if exists bonos_crear on public.bonos;
create policy bonos_crear on public.bonos for insert
  with check (public.es_activo() and (coalesce(data->>'tipo','') <> 'Cortesía' or public.rol_actual() = 'admin'));

-- ---------- 3. Auditoría (trazabilidad) ----------
create table if not exists public.auditoria (
  id          bigint generated always as identity primary key,
  tabla       text not null,
  registro_id text not null,
  accion      text not null,
  usuario     uuid,
  antes       jsonb,
  despues     jsonb,
  fecha       timestamptz not null default now()
);
alter table public.auditoria enable row level security;
drop policy if exists auditoria_ver on public.auditoria;
create policy auditoria_ver on public.auditoria for select
  using (public.rol_actual() in ('admin','tesoreria'));

create or replace function public.tg_auditar() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' then new.updated_at := now(); new.updated_by := coalesce(auth.uid(), new.updated_by); end if;
  insert into public.auditoria(tabla, registro_id, accion, usuario, antes, despues)
  values (tg_table_name,
          coalesce(new.id, old.id),
          tg_op,
          auth.uid(),
          case when tg_op in ('UPDATE','DELETE') then old.data end,
          case when tg_op in ('INSERT','UPDATE') then new.data end);
  return coalesce(new, old);
end $$;

do $$
declare t text;
begin
  foreach t in array array['clientes','reservas','anticipos','mesas','bonos','cartera'] loop
    execute format('drop trigger if exists auditar on public.%I', t);
    execute format('create trigger auditar before insert or update or delete on public.%I for each row execute function public.tg_auditar()', t);
  end loop;
end $$;

-- ---------- 4. Formulario público del cliente ----------
-- El cliente (sin usuario) solo puede llamar esta función. Crea o actualiza el
-- cliente buscando por celular. No devuelve datos.
create or replace function public.registrar_cliente(p jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare
  tel text := regexp_replace(coalesce(p->>'telefono',''), '\D', '', 'g');
  limpio jsonb;
  existente text;
begin
  if length(tel) < 7 or length(tel) > 15 then raise exception 'Celular no válido'; end if;
  if length(coalesce(p->>'nombre','')) < 3 or length(p->>'nombre') > 150 then raise exception 'Nombre no válido'; end if;
  -- solo se aceptan estos campos desde el formulario
  limpio := jsonb_strip_nulls(jsonb_build_object(
    'nombre',         left(p->>'nombre',150),
    'telefono',       tel,
    'email',          left(p->>'email',150),
    'facturaPropia',  coalesce((p->>'facturaPropia')::boolean,false),
    'tipoDoc',        left(p->>'tipoDoc',60),
    'numDoc',         left(regexp_replace(coalesce(p->>'numDoc',''), '[^0-9A-Za-z]', '', 'g'),20),
    'dv',             left(p->>'dv',2),
    'direccion',      left(p->>'direccion',200),
    'origen',         'formulario',
    'avisoAceptado',  to_char(now() at time zone 'America/Bogota','YYYY-MM-DD'),
    'autorizaDatos',  to_char(now() at time zone 'America/Bogota','YYYY-MM-DD')
  ));
  if coalesce((p->>'facturaPropia')::boolean,false) then limpio := limpio || '{"siesa":"Por crear"}'; end if;
  select id into existente from public.clientes where data->>'telefono' = tel limit 1;
  if existente is not null then
    update public.clientes set data = data || limpio where id = existente;
  else
    insert into public.clientes(id, data, updated_by)
    values ('cli-' || replace(gen_random_uuid()::text,'-',''), limpio || jsonb_build_object('creado', limpio->>'avisoAceptado'), null);
  end if;
end $$;
revoke all on function public.registrar_cliente(jsonb) from public;
grant execute on function public.registrar_cliente(jsonb) to anon, authenticated;

-- ---------- 5. Soportes de pago (Storage privado) ----------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('soportes','soportes', false, 2097152, array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do nothing;

drop policy if exists soportes_leer on storage.objects;
create policy soportes_leer on storage.objects for select
  using (bucket_id = 'soportes' and public.es_activo());
drop policy if exists soportes_subir on storage.objects;
create policy soportes_subir on storage.objects for insert
  with check (bucket_id = 'soportes' and public.es_activo());
drop policy if exists soportes_actualizar on storage.objects;
create policy soportes_actualizar on storage.objects for update
  using (bucket_id = 'soportes' and public.es_activo());
drop policy if exists soportes_borrar on storage.objects;
create policy soportes_borrar on storage.objects for delete
  using (bucket_id = 'soportes' and public.rol_actual() = 'admin');

-- ---------- 6. Tiempo real (todas las pantallas se actualizan solas) ----------
do $$
declare t text;
begin
  foreach t in array array['clientes','reservas','anticipos','mesas','bonos','cartera'] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

-- ---------- 7. Vistas para reportes y contabilidad ----------
create or replace view public.v_anticipos with (security_invoker = true) as
select a.id,
       a.data->>'estado'            as estado,
       a.data->>'concepto'          as concepto,
       (a.data->>'valor')::numeric  as valor,
       a.data->>'medio'             as medio,
       (a.data->>'fechaPago')::date as fecha_pago,
       nullif(a.data->>'fechaAplicacion','')::date as fecha_aplicacion,
       a.data->>'rc'                as recibo_caja,
       a.data->>'factura'           as factura,
       a.data->>'ajuste'            as ajuste_contable,
       c.data->>'nombre'            as cliente,
       c.data->>'numDoc'            as documento,
       r.data->>'tipo'              as tipo_reserva,
       a.updated_at
from public.anticipos a
left join public.clientes c on c.id = a.data->>'clienteId'
left join public.reservas r on r.id = a.data->>'reservaId';

create or replace view public.v_cartera with (security_invoker = true) as
select x.id,
       c.data->>'nombre'                         as cliente,
       x.data->>'factura'                        as factura,
       (x.data->>'valor')::numeric               as valor,
       (x.data->>'fechaFactura')::date           as fecha_factura,
       (x.data->>'vence')::date                  as vence,
       coalesce((select sum((p->>'valor')::numeric) from jsonb_array_elements(x.data->'pagos') p),0) as pagado,
       x.data->'contacto'->>'nombre'             as contacto,
       x.data->'contacto'->>'telefono'           as contacto_telefono
from public.cartera x
left join public.clientes c on c.id = x.data->>'clienteId';

-- =====================================================================
--  Después de correr este archivo:
--  1) Authentication → Users → "Add user" (correo + contraseña) por cada persona.
--  2) Crear su perfil (cambia el correo, nombre y rol):
--     insert into public.perfiles(user_id, nombre, rol)
--     select id, 'Gerencia', 'admin' from auth.users where email = 'correo@volver.com';
--  Ver docs/INSTRUCTIVO-MONTAJE.md
-- =====================================================================
