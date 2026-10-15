// =====================================================================
// Campi App-Test · Einstellungen
//
// Trage hier die Werte aus deinem Supabase-Projekt ein
// (Project Settings > API Keys bzw. Data API):
//   supabaseUrl: die Project URL, z. B. https://abcdefgh.supabase.co
//   supabaseKey: der "publishable" Key (beginnt mit sb_publishable_)
//                oder der alte "anon" Key (beginnt mit eyJ)
//
// Dieser Schlüssel darf öffentlich sein: Die Datenbank ist über Regeln
// geschützt. NIEMALS den "secret" oder "service_role" Key eintragen!
// =====================================================================
window.CAMPI_CONFIG = {
  supabaseUrl: 'https://DEINPROJEKT.supabase.co',
  supabaseKey: 'DEIN_PUBLISHABLE_KEY',

  // true = der Test startet beim Öffnen automatisch
  // false = nur die App (Test dann über einen Link, der auf #studie endet)
  studie: true,

  // optional: Kontakt für Rückfragen, wird den Testpersonen angezeigt
  kontakt: '',

  // Name, der über dem Test steht
  projekt: 'Studienprojekt Campi'
};
