# Arquitectura y seguridad

## Componentes

```
Navegador (PC de caja, tablet, celular)
        │  HTTPS
        ▼
GitHub Pages  ──  index.html + config.js   (código público, sin datos)
        │  supabase-js (llave pública + sesión del usuario)
        ▼
Supabase (cuenta de Volver)
  ├─ Auth .......... usuarios con correo y contraseña
  ├─ Postgres ...... perfiles, clientes, reservas, anticipos, mesas, bonos, cartera, auditoria
  ├─ RLS ........... reglas de acceso por usuario activo y rol
  ├─ Realtime ...... todas las pantallas se actualizan solas
  └─ Storage ....... bucket privado "soportes" (fotos / PDF de pagos)
```

- **Sin servidor propio ni compilación**: un solo archivo HTML. Fácil de mantener y de alojar.
- **Dominio**: la página se puede servir como `app.volversiemprevolver.com` (registro CNAME hacia GitHub Pages). Ver instructivo.

## Roles

| Rol (`perfiles.rol`) | Área | Puede |
|---|---|---|
| `reservas` | Reservas | Todo lo operativo; asignar mesas |
| `caja` | Caja | Operativo; no asigna mesas a reservas |
| `tesoreria` | Tesorería y contabilidad | Operativo; ve la auditoría |
| `admin` | Gerencia / Administración | Todo; cortesías; borrar registros; administrar usuarios; ve la auditoría |

## Seguridad

- **RLS (Row Level Security)** en todas las tablas: sin usuario activo no se lee ni se escribe nada.
- La llave de `config.js` es la **anon/publishable key**: es pública por diseño. La **service_role key nunca** va en el código.
- Borrar registros: solo Gerencia. Cortesías: solo Gerencia (también validado en la base de datos).
- **Auditoría**: cada creación, cambio o borrado queda en `auditoria` con usuario, fecha, valor anterior y nuevo.
- **Soportes de pago** en bucket **privado**; se ven con enlaces firmados que vencen en 15 minutos.
- **Formulario público**: el cliente solo ejecuta `registrar_cliente()`, que valida y limpia los campos. No puede leer datos.
- Datos personales: el formulario pide autorización de tratamiento de datos (Ley 1581 de 2012).

## Decisiones técnicas

| Decisión | Motivo |
|---|---|
| Cuenta Supabase a nombre de Volver | Los datos son del cliente; Soporte TI entra como administrador invitado |
| Registros como documentos JSON (`data jsonb`) | Permite ajustar campos sin migraciones mientras el proceso se termina de definir. Las vistas `v_anticipos` y `v_cartera` dan columnas para reportes |
| Repositorio público | GitHub Pages gratuito; el código no contiene datos ni secretos |
| Sin integración directa a SIESA (por ahora) | SIESA no publica API; se evalúa con su distribuidor. Mientras tanto, datos listos para copiar |
| Mensajes de WhatsApp con enlace wa.me | Funciona ya con el WhatsApp actual. Nivel 2: API de WhatsApp Business (coexistencia) |
