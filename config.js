// =====================================================================
// Campi App-Test · Einstellungen
// =====================================================================
window.CAMPI_CONFIG = {
  supabaseUrl: 'https://qxexshbmajwcyrytfcsi.supabase.co',
  supabaseKey: 'sb_publishable_NZp0QdRsg9dTe4RsDfQB-w_kIB5CWsY',

  // true = der Test startet beim Öffnen automatisch
  // false = nur die App (Test dann über einen Link, der auf #studie endet)
  studie: true,

  // 'test'  = normaler App-Test (Standard)
  // 'pilot' = jede Person, die die Seite öffnet, wird zur Pilotphase eingeladen.
  //           Meist besser: 'test' lassen und für den Pilot den Link mit ?pilot verschicken.
  modus: 'test',
  
  // optional: Kontakt für Rückfragen, wird den Testpersonen angezeigt
  kontakt: '',

  // Name, der über dem Test steht
  projekt: 'Studienprojekt Campi'
};



