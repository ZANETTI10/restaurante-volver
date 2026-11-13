# Restaurante Volver · Gestión de reservas

Aplicación web interna de **Volver** (huerta y cocina de montaña, Envigado) para manejar en un solo lugar:

| Módulo | Para qué sirve | Área que lo usa |
|---|---|---|
| **Reservas** | Asistente de 5 pasos: fecha y mesa, cliente, datos de facturación (con aviso), anticipo con soporte | Reservas |
| **Eventos** | Tablero de todos los eventos: valor, pagado, saldo, estado, cartera | Gerencia |
| **Mesas** | Mapa del salón (35 adentro, 1 terraza, 6 afuera): reservada, ocupada, pidió la cuenta | Reservas / Salón |
| **Caja** | Antes de facturar en SIESA: alerta de anticipos y bonos del cliente, datos para copiar | Caja |
| **Anticipos** | Recorrido completo: registro → verificación (recibo de caja) → aplicación en factura (QR) → ajuste contable | Todas |
| **Cartera** | Cuentas por cobrar de eventos con plazo, contacto de cartera y alerta de vencimiento | Tesorería / Gerencia |
| **Bonos** | Vendidos y de cortesía, código único, redención completa con trazabilidad | Caja / Gerencia |
| **Clientes** | Base de clientes con sus datos de facturación electrónica | Todas |
| **Contabilidad** | Pendientes de SIESA: pagos por verificar, ajustes, terceros por crear, devoluciones | Tesorería y contabilidad |
| **TI** | Crear y administrar usuarios sin correo (usuario + contraseña), roles y permisos | Administrador (TI) |

Además incluye un **formulario público** (`#registro`) para que el cliente llene sus propios datos de facturación y acepte el aviso de factura.

## Cómo probarla

- **Modo demostración:** abrir `index.html` (o la página publicada) con `config.js` vacío. Usa datos de ejemplo en memoria; se reinician al recargar.
- **Modo real:** llenar `config.js` con la URL y la llave pública de Supabase. Pide usuario y contraseña, y los datos quedan guardados y compartidos en tiempo real.

## Estructura

```
index.html                  Aplicación completa (HTML + CSS + JS, sin compilación)
config.js                   Conexión a Supabase (vacío = modo demostración)
supabase/001_esquema.sql    Tablas, roles, seguridad (RLS), auditoría, Storage y vistas
supabase/functions/usuarios Función segura para crear y administrar usuarios
docs/                       Documentación del proyecto
```

## Documentación

- [Bitácora del proyecto](docs/BITACORA.md): qué se hizo, cuándo y por qué.
- [Requerimientos de Volver](docs/REQUERIMIENTOS.md)
- [Arquitectura y seguridad](docs/ARQUITECTURA.md)
- [Modelo de datos](docs/MODELO-DE-DATOS.md)
- [Instructivo de montaje](docs/INSTRUCTIVO-MONTAJE.md): Supabase, usuarios, GitHub Pages y dominio.
- [Manual de uso por área](docs/MANUAL-DE-USO.md)
- [Preguntas pendientes](docs/PENDIENTES.md)

---
Desarrollado por **Soporte TI** para Restaurante Volver · 2026
