# Requerimientos · Restaurante Volver

Lo que pidió Volver, organizado por área. Estado: ✅ hecho en la versión de prueba · 🔜 pendiente.

## Reservas
- ✅ Pedir datos de registro y facturación al reservar.
- ✅ Preguntar "¿Desea la factura a nombre propio?". Si sí: nombre completo, tipo de documento, número, dirección, correo y teléfono (obligatorios).
- ✅ Aviso al cliente: si no pide la factura desde el inicio, no se podrá cambiar después. Queda registrada la fecha de aceptación.
- ✅ Asignar mesa al reservar (una o varias), con disponibilidad por fecha y hora.
- ✅ La mesa solo la asigna Reservas o Gerencia (interno).
- ✅ Anotar si la reserva va con torta y si está pagada o falta pago.
- ✅ Seguimiento de la reserva con soporte de pago (foto de la transferencia).
- ✅ Formulario para que el cliente llene sus propios datos.
- 🔜 Definir si se deja de usar Apparta (lo define Gerencia).

## Anticipos
- ✅ Registrar anticipos ligados al cliente y a la reserva, con soporte obligatorio.
- ✅ Alerta en caja cuando el cliente tiene anticipos pendientes por cruzar.
- ✅ Flujo contable: verificación con recibo de caja (cuenta 28050501) → aplicación en factura con medio QR → ajuste contable.
- ✅ Devoluciones: solicitud y registro de la consignación.
- ✅ Filtro de anticipos de eventos para Contabilidad.
- 🔜 Migrar los 24 anticipos pendientes del Excel de control.

## Eventos (Gerencia)
- ✅ Tablero de todos los eventos: valor, pagado, saldo, estado.
- ✅ Valor cotizado y detalle del evento (menú, montaje, decoración).
- 🔜 Plan de pagos con fechas (anticipo, abono, saldo).
- 🔜 Cotización imprimible para el cliente.
- 🔜 Más ideas de Gerencia para eventos (por recibir).

## Cartera
- ✅ Cuentas por cobrar de eventos con plazo de pago.
- ✅ Contacto de cartera del cliente (nombre, cargo, celular, correo).
- ✅ Alerta cuando está por vencer (5 días) y cuando ya está vencida.
- ✅ Pagos parciales y recordatorio por WhatsApp.

## Bonos
- ✅ Bonos vendidos y de cortesía, con código único.
- ✅ Cortesías solo las autoriza Gerencia / líderes.
- ✅ Se consumen completos; trazabilidad de venta y redención (factura).
- 🔜 Confirmar con Contabilidad: ¿se factura al vender o al redimir? ¿vencimiento?

## Usuarios
- ✅ Roles: Reservas, Caja, Tesorería y contabilidad, Gerencia / Administración.
- ✅ Usuario propio para Contabilidad y para Gerencia (modo real).

## SIESA
- ✅ Datos listos para copiar (cliente, terceros por crear, ajustes).
- 🔜 Evaluar con SIESA o su distribuidor: API o servicios web para crear terceros y consultar facturas.
