# Instructivo de montaje · paso a paso

Responsable: Soporte TI. Tiempo estimado: 1 a 2 horas.

## Paso 1 · Cuenta de Supabase a nombre de Volver
1. Con un correo **de Volver** (por ejemplo sistemas@ o administracion@), entrar a https://supabase.com y crear la cuenta.
2. Crear la organización **Restaurante Volver** (plan Free para empezar).
3. Organization → Team → **Invite**: invitar el correo de Soporte TI como **Owner** o **Administrator**.
4. Crear el proyecto **restaurante-volver**, región `sa-east-1` (São Paulo, la más cercana a Colombia). Guardar la contraseña de la base de datos en el gestor de contraseñas de Volver.

## Paso 2 · Base de datos
1. Supabase → **SQL Editor** → New query.
2. Pegar todo `supabase/001_esquema.sql` → **Run**. Debe terminar sin errores.
3. Verificar en **Table Editor**: perfiles, clientes, reservas, anticipos, mesas, bonos, cartera, auditoria.
4. Verificar en **Storage**: bucket `soportes` (privado).

## Paso 3 · Usuarios
1. Authentication → **Sign In / Providers** → Email: dejar activo; desactivar "Allow new users to sign up" (solo Gerencia crea usuarios).
2. Authentication → Users → **Add user → Create new user**: correo y contraseña temporal de cada persona. Marcar "Auto confirm user".
3. Crear su perfil en SQL Editor (repetir por persona, cambiando correo, nombre y rol):
   ```sql
   insert into public.perfiles(user_id, nombre, rol)
   select id, 'Gerencia', 'admin' from auth.users where email = 'gerencia@correo.com';
   ```
   Roles: `reservas`, `caja`, `tesoreria`, `admin`.
4. Después, Gerencia puede cambiar área o desactivar usuarios desde la pantalla **Usuarios** de la aplicación.

## Paso 4 · Conectar la aplicación
1. Supabase → Project Settings → **API**: copiar `Project URL` y la llave **anon / publishable**.
2. En el repositorio, editar `config.js`:
   ```js
   window.VOLVER_CONFIG = { supabaseUrl: 'https://xxxx.supabase.co', supabaseAnonKey: 'eyJ...' };
   ```
3. Nunca usar la llave **service_role**.

## Paso 5 · Publicar (GitHub Pages)
1. GitHub → repositorio → Settings → **Pages** → Source: *Deploy from a branch* → `main` / `(root)` → Save.
2. La página queda en `https://zanetti10.github.io/restaurante-volver/`.
3. Supabase → Authentication → URL Configuration → **Site URL**: poner esa dirección (o el dominio propio).

## Paso 6 · Dominio propio (opcional)
1. En el DNS de volversiemprevolver.com crear: `app` → **CNAME** → `zanetti10.github.io`.
2. GitHub → Settings → Pages → Custom domain: `app.volversiemprevolver.com` → Save → activar **Enforce HTTPS** cuando esté disponible.
3. Actualizar el Site URL de Supabase al dominio nuevo.

## Paso 7 · Pruebas con el equipo
- [ ] Cada persona entra con su usuario y ve su área.
- [ ] Reservas crea una reserva con factura a nombre propio, torta y anticipo con soporte.
- [ ] Tesorería verifica el anticipo (recibo de caja).
- [ ] Caja busca al cliente, ve la alerta y aplica el anticipo en factura.
- [ ] Contabilidad registra el ajuste.
- [ ] Gerencia crea un bono de cortesía; Caja lo redime.
- [ ] Se crea una cuenta por cobrar de un evento y se registra un pago.
- [ ] Desde la tablet: mesas, sentar, pedir la cuenta.
- [ ] Formulario del cliente (`#registro`) desde un celular sin sesión.
- [ ] Dos equipos abiertos a la vez: los cambios aparecen solos en el otro.

## Paso 8 · Migración del Excel de anticipos
Cargar los anticipos pendientes de `CONTROL_DE_ANTICIPOS_VOLVER.xlsx` (Soporte TI lo hace con un script) y asociarlos a sus clientes desde la pantalla de cada anticipo.

## Copias de seguridad
- Plan Free: Supabase no garantiza respaldos descargables. Recomendado: plan Pro cuando entre en producción, o exportar semanalmente (Database → Backups / `pg_dump`).
