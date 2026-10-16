// =====================================================================
// Campi · Einstellungen für App-Test und Pilotphase
// =====================================================================
window.CAMPI_CONFIG = {
  supabaseUrl: 'https://qxexshbmajwcyrytfcsi.supabase.co',
  supabaseKey: 'sb_publishable_NZp0QdRsg9dTe4RsDfQB-w_kIB5CWsY',

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
