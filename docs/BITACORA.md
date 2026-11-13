# Bitácora del proyecto · Restaurante Volver

Registro cronológico de cada paso, decisión y cambio. Se actualiza en cada entrega.

---

## 2026-11-12 · Levantamiento y primera versión de prueba

**Pedido inicial (Contabilidad de Volver):**
- Al hacer una reserva con anticipo, pedir al cliente sus datos de registro y facturación.
- Preguntar si quiere factura a nombre propio; si sí: nombre completo, tipo y número de documento, dirección, correo y teléfono.
- Registrar los anticipos con los datos de quien reserva.
- Alerta al facturar: "este cliente tiene anticipos pendientes por cruzar".

**Insumos revisados:**
- `CONTROL_DE_ANTICIPOS_VOLVER.xlsx`: 231 anticipos registrados, 24 sin aplicar o con novedad (sin redimir, devoluciones pendientes, fechas mal digitadas). Casi ninguno tiene documento del cliente.
- Sitio web volversiemprevolver.com: colores (verde oliva #2F3809, gris cálido #5B5754, rosado #CC3366, beige #EFEEEC) y tipografías (Editorial New → se usa Fraunces; Martian Mono).
- Documento "ANTICIPOS Y RESERVAS" con las respuestas de Contabilidad:
  - Los anticipos los registra Tesorería con recibo de caja en la cuenta **28050501**.
  - En caja se cierran con medio de pago **QR** y luego Contabilidad hace el ajuste contable.
  - Los clientes creados desde el POS suben como consumidor final; los de eventos y cuentas por cobrar los crea Contabilidad desde financiero.
  - Notas crédito: problema frecuente cuando el cliente pide factura a su nombre después.
  - Hasta 3 cajeras; PC entre semana y tablet los fines de semana.
  - Mesas: 35 adentro, 1 terraza, 6 afuera.
  - Soportes de pago hoy solo en WhatsApp.
  - Cortesías las autorizan líderes y administradora; los bonos se consumen completos.

**Decisiones:**
- Se construye primero una **versión de prueba** (datos de ejemplo) para validar con Volver antes de montar la real.
- En pantalla solo aparecen **cargos/áreas, no nombres de personas** (pedido de Soporte TI).
- Integración con SIESA: no hay API pública documentada. Se arranca **sin conexión** (datos listos para copiar) y luego se evalúa lectura/escritura con SIESA o su distribuidor.

**Entregas del día (versión de prueba publicada como artefacto privado):**
1. Reservas en 5 pasos, aviso de factura con aceptación registrada, anticipos con soporte obligatorio.
2. Flujo contable del anticipo: Por verificar → Verificado (recibo de caja) → Aplicado en factura (QR) → Conciliado (ajuste).
3. Caja con alerta de anticipos y bonos, datos de facturación con botón Copiar.
4. Contabilidad: pagos por verificar, ajustes pendientes, terceros por crear en SIESA, devoluciones.
5. Bonos vendidos/cortesía con código único y trazabilidad.
6. Mesa obligatoria en la reserva con mapa de disponibilidad (franja de 2,5 h) y selección múltiple.
7. Pedido de Contabilidad: mesa solo la asigna Reservas/Gerencia (interno); torta en la reserva (pagada / falta pago); **cartera** de eventos con plazo, contacto de cartera y alerta de vencida.
8. Pedido de Gerencia: **tablero de eventos** (valor, pagado, saldo, estado, cartera) y filtro de anticipos de eventos para Contabilidad.
9. Mensajes de WhatsApp pre-escritos (confirmación, aviso de factura, recibo, bono, recordatorio de cartera).

## 2026-11-12 · Montaje del repositorio y versión real

- Se crea el repositorio **ZANETTI10/restaurante-volver** (público, para usar GitHub Pages gratis; no contiene datos de clientes).
- Se autoriza la app de Claude en GitHub **solo para este repositorio**.
- Decisión: los datos de Volver irán en una **cuenta de Supabase a nombre de Volver** (correo de Volver), con Soporte TI invitado como administrador. Así los datos son del cliente.
- Se agrega a la aplicación el **modo real**: login por correo, perfiles con rol, datos en Supabase, tiempo real entre equipos, soportes en Storage privado, formulario público por función segura, pantalla de usuarios para Gerencia.
- Se crea `supabase/001_esquema.sql` con tablas, RLS, auditoría, Storage y vistas.
- Mientras no exista el proyecto Supabase, la página publicada abre en **modo demostración**.

**Siguiente paso:** crear la cuenta Supabase de Volver → aplicar el esquema → crear usuarios → llenar `config.js` → pruebas con el equipo → dominio propio.

### Avance 19:50
- Código subido a `main` (autor: Soporte TI, correo privado de GitHub).
- **GitHub Pages activo**: https://zanetti10.github.io/restaurante-volver/ (abre en modo demostración hasta configurar Supabase).
- Descripción del repositorio corregida y enlace al sitio agregado.
- Pendiente: cuenta Supabase de Volver (la crea Volver con su correo e invita a Soporte TI) → Soporte TI crea el proyecto, aplica `001_esquema.sql`, crea usuarios y llena `config.js`.

## 2026-11-12 (noche) · Sección TI y usuarios sin correo

**Pedido de Soporte TI:** crear dentro del programa una parte llamada **TI** para crear y administrar usuarios **sin correo**, solo con usuario y contraseña; que cada usuario muestre qué rol tiene y qué va a manejar. El usuario de Soporte TI debe ser **Administrador**.

**Hecho:**
- Nuevo rol `ti` (**Administrador (TI)**): acceso total y sección **TI**.
- Cada rol ve solo sus módulos (menú y acceso filtrados). Tabla de módulos por rol en `docs/ARQUITECTURA.md`.
- Ingreso con **usuario** (internamente `usuario@usuarios.volver.app`).
- Pantalla **TI → Usuarios**: crear (con contraseña temporal generada y mostrada una vez), editar rol/nombre, desactivar (bloquea el ingreso), restablecer contraseña. Al elegir el rol se ve qué maneja.
- Cambio de contraseña **obligatorio** al primer ingreso y opción "Cambiar contraseña" para todos.
- Nueva Edge Function `supabase/functions/usuarios` (única con llave de servicio; valida que quien llama sea TI; registra en auditoría).
- Esquema: `perfiles.usuario`, `perfiles.debe_cambiar`, rol `ti`, función `marcar_clave_cambiada()`; perfiles ya no se editan con la llave pública.
- Primer usuario: `administrador` (rol TI). Su contraseña temporal se entregó por chat privado, no está en el repositorio.
- Probado en demostración y en modo real simulado (login por usuario, cambio obligatorio, crear usuario, restablecer).
