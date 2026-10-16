// =====================================================================
// Campi · Einstellungen für App-Test und Pilotphase
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

  // true = der App-Test (3 Aufgaben + Fragebogen) startet beim Öffnen automatisch
  // false = nur die App (Test dann über einen Link, der auf #studie endet)
  studie: true,

  // 'test'  = normaler App-Test (Standard)
  // 'pilot' = jede Person, die die Seite öffnet, wird zur Pilotphase eingeladen.
  //           Meist besser: 'test' lassen und für den Pilot den Link mit ?pilot verschicken.
  modus: 'test',

  // optional: Kontakt für Rückfragen, wird den Testpersonen angezeigt
  kontakt: '',

  // Name, der über dem Test steht
  projekt: 'Studienprojekt Campi',

  // optional: Adresse einer eigenen daten.json (Speiseplan, Fristen, Veranstaltungen).
  // Leer lassen: Die App nimmt daten.json aus diesem Repository, die der Workflow
  // "Daten aktualisieren" jede Nacht um 1 Uhr neu schreibt.
  datenUrl: ''
};
