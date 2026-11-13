/*
  Configuración de conexión a Supabase — Restaurante Volver
  ---------------------------------------------------------
  - Si supabaseUrl y supabaseAnonKey están vacíos, la aplicación abre en MODO DEMOSTRACIÓN
    (datos de ejemplo en memoria, sin login).
  - Para el MODO REAL, pega aquí la URL del proyecto y la "anon / publishable key"
    (Supabase → Project Settings → API). Esa llave es pública por diseño: la seguridad
    la dan las políticas RLS definidas en supabase/001_esquema.sql.
  - NUNCA pongas aquí la "service_role key".
*/
window.VOLVER_CONFIG = {
  supabaseUrl: '',
  supabaseAnonKey: ''
};
