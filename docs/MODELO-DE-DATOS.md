# Modelo de datos

Cada tabla operativa tiene: `id` (texto), `data` (JSON con los campos de abajo), `created_at`, `updated_at`, `updated_by`.

## clientes
| Campo | Descripción |
|---|---|
| nombre, telefono, email | Datos básicos (teléfono solo dígitos) |
| facturaPropia | `true` = factura a su nombre; `false` = consumidor final |
| tipoDoc, numDoc, dv, direccion | Datos de facturación electrónica (dv solo para NIT) |
| avisoAceptado | Fecha en que aceptó el aviso de factura |
| autorizaDatos | Fecha de autorización de tratamiento de datos (formulario) |
| siesa | `Por crear` / `Creado` en SIESA financiero |
| origen | `formulario` si lo llenó el cliente |

## reservas
| Campo | Descripción |
|---|---|
| clienteId | Cliente que reserva |
| fecha, hora, personas | |
| tipo | Restaurante / Evento / Torta / Celebración / Otro |
| ocasion, notas, origen | Origen: WhatsApp, Apparta, Teléfono, Instagram, Presencial |
| mesas | Lista de mesas asignadas (`1`…`35`, `T1`, `F1`…`F6`) |
| estado | Pendiente, Confirmada, Llegó, Finalizada, No asistió, Cancelada |
| torta | `{lleva, detalle, valor, estado: Pagada / Falta pago, anticipoId}` |
| valorEvento, detalleEvento | Solo eventos: valor cotizado y detalle |
| hist | Historial `[{f, h, u, t}]` (fecha, hora, área, texto) |

## anticipos
| Campo | Descripción |
|---|---|
| clienteId, reservaId | A quién y a qué reserva pertenece |
| concepto, valor, medio, fechaPago, referencia | |
| fechaAplicacion | Día en que se debe cruzar (día de la reserva) |
| soporteId, soporteMes | Archivo en Storage: `soportes/AAAA-MM/<soporteId>.jpg` |
| estado | Por verificar → Verificado → Aplicado en factura → Conciliado · Devolución solicitada → Devuelto · Anulado |
| rc | N° recibo de caja SIESA (al verificar) |
| factura, fechaFactura | Factura donde se aplicó (medio QR) |
| ajuste | N° documento de ajuste contable |
| devMotivo, devRef | Devolución |
| hist | Trazabilidad |

## cartera
| Campo | Descripción |
|---|---|
| clienteId, reservaId, concepto | |
| factura, fechaFactura, valor | |
| plazoDias, vence | Plazo y fecha de vencimiento |
| contacto | `{nombre, cargo, telefono, email}` del cliente |
| pagos | `[{f, valor, ref, u}]` pagos parciales |
| hist | Trazabilidad |

## bonos
| Campo | Descripción |
|---|---|
| codigo | `VLV-XXXX` único |
| tipo | Vendido / Cortesía |
| valor, vence, comprador, beneficiario, telefono | |
| medio, soporteId (vendido) · autorizadoPor, motivo (cortesía) | |
| estado | Activo, Redimido, Anulado (Vencido se calcula) |
| redFecha, redFactura, redPor | Redención |

## mesas
Estado del salón en vivo: `{estado: libre/ocupada/cuenta, reservaId, desde}`. La distribución de mesas (35 adentro, 1 terraza, 6 afuera, capacidades) está configurada en `index.html` → `ZONAS`.

## perfiles
`user_id`, `usuario` (para entrar, sin correo), `nombre`, `rol` (reservas, caja, tesoreria, admin, ti), `activo`, `debe_cambiar` (contraseña temporal pendiente de cambio).

## auditoria
`tabla`, `registro_id`, `accion` (INSERT/UPDATE/DELETE), `usuario`, `antes`, `despues`, `fecha`.
