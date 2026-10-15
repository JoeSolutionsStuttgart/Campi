-- =====================================================================
-- Campi App-Test · Datenbank für Supabase
--
-- So geht's: Im Supabase-Dashboard links "SQL Editor" öffnen,
-- diesen kompletten Text einfügen, GANZ UNTEN deine Admin-E-Mail
-- eintragen und auf "Run" klicken. Das Skript kann gefahrlos
-- mehrfach ausgeführt werden.
--
-- Sicherheit: Testpersonen dürfen nur über die Funktion test_speichern
-- neue Daten anlegen und die aktiven Fragen lesen. Lesen, ändern und löschen darf nur, wer als
-- Admin eingetragen und angemeldet ist (Row Level Security).
-- =====================================================================


-- 1. Hilfstypen: begrenzen die Textlänge, damit niemand die Datenbank
--    mit riesigen Einträgen füllen kann
do $$ begin
  create domain public.kurztext as text check (char_length(value) <= 300);
exception when duplicate_object then null; end $$;

do $$ begin
  create domain public.langtext as text check (char_length(value) <= 2000);
exception when duplicate_object then null; end $$;


-- 2. Tabellen ----------------------------------------------------------

-- Wer die Auswertung sehen und Fragen bearbeiten darf
create table if not exists public.admins (
  email text primary key check (email = lower(email))
);

-- Eine Zeile pro Testperson (angelegt nach der Einwilligung)
create table if not exists public.sitzungen (
  id               uuid primary key,
  erstellt         timestamptz not null default now(),
  version          kurztext,
  gruppe           kurztext,          -- "mit Quelle" / "ohne Quelle" (A/B-Test KI-Antwort)
  geraet           kurztext,          -- Handy / Tablet / Computer
  betriebssystem   kurztext,
  browser          kurztext,
  sprache          kurztext,
  zeitzone         kurztext,
  bildschirm       kurztext,          -- z. B. 390x844
  fenster          kurztext,          -- sichtbare Fläche im Browser
  pixeldichte      numeric,
  touch            boolean,
  dunkelmodus      boolean,
  weniger_bewegung boolean,
  verbindung       kurztext,          -- z. B. 4g, wifi (falls der Browser es verrät)
  quelle           kurztext,          -- aus dem Link, z. B. ?quelle=instagram
  kampagne         kurztext,
  referrer         kurztext,          -- nur die Domain, von der jemand kam
  semester         kurztext,
  letzte_raumsuche kurztext,
  ladezeit_ms      integer
);

-- Alles, was während des Tests passiert (Ansichten, Klicks, Suchen, Chat …)
create table if not exists public.ereignisse (
  id         uuid primary key,
  sitzung_id uuid not null references public.sitzungen(id) on delete cascade,
  erstellt   timestamptz not null default now(),
  zeit_ms    integer check (zeit_ms between 0 and 86400000),  -- Millisekunden seit Teststart
  typ        kurztext not null,
  schritt    kurztext,
  ansicht    kurztext,
  daten      jsonb not null default '{}'::jsonb check (pg_column_size(daten) <= 4000)
);
create index if not exists ereignisse_sitzung_idx on public.ereignisse (sitzung_id, zeit_ms);
create index if not exists ereignisse_typ_idx on public.ereignisse (typ);

-- Ergebnis der drei Aufgaben, eine Zeile pro abgeschlossenem Test
create table if not exists public.ergebnisse (
  sitzung_id          uuid primary key references public.sitzungen(id) on delete cascade,
  erstellt            timestamptz not null default now(),
  a1_ergebnis         kurztext,       -- gefunden / aufgegeben
  a1_sekunden         numeric,
  a1_tipps            integer,
  a1_weg              kurztext,
  a1_verstaendlich    smallint check (a1_verstaendlich between 1 and 5),
  a2_ergebnis         kurztext,       -- beantwortet / aufgegeben
  a2_sekunden         numeric,
  a2_fragen           integer,
  a2_vertrauen        smallint check (a2_vertrauen between 1 and 5),
  a2_lieber           kurztext,
  a3_sekunden         numeric,
  a3_bereiche         text[] check (cardinality(a3_bereiche) <= 40),
  dauer_sekunden      numeric,
  fragebogen_sekunden numeric
);

-- Dein Fragenkatalog (wird auf der Admin-Seite bearbeitet)
create table if not exists public.fragen (
  id         uuid primary key default gen_random_uuid(),
  erstellt   timestamptz not null default now(),
  position   integer not null default 0,
  typ        text not null check (typ in ('einfach', 'mehrfach', 'skala', 'text')),
  frage      kurztext not null check (char_length(frage) >= 1),
  hinweis    kurztext,
  optionen   text[] not null default '{}' check (cardinality(optionen) <= 20),
  skala_min  kurztext,
  skala_max  kurztext,
  pflicht    boolean not null default true,
  aktiv      boolean not null default true,
  schluessel text unique              -- markiert Fragen, die in die Hypothesen-Auswertung eingehen
);

-- Antworten auf den Fragenkatalog
create table if not exists public.antworten (
  id         uuid primary key,
  sitzung_id uuid not null references public.sitzungen(id) on delete cascade,
  frage_id   uuid references public.fragen(id) on delete set null,
  erstellt   timestamptz not null default now(),
  frage      kurztext,                -- Fragetext zum Zeitpunkt der Antwort
  typ        kurztext,
  wert       jsonb not null check (pg_column_size(wert) <= 4000)
);
create index if not exists antworten_frage_idx on public.antworten (frage_id);
create index if not exists antworten_sitzung_idx on public.antworten (sitzung_id);


-- 3. Admin-Prüfung -----------------------------------------------------
create or replace function public.ist_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admins a
    where a.email = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;
revoke all on function public.ist_admin() from public;
grant execute on function public.ist_admin() to anon, authenticated;


-- 4. Zugriffsregeln (Row Level Security) ------------------------------
alter table public.admins     enable row level security;
alter table public.sitzungen  enable row level security;
alter table public.ereignisse enable row level security;
alter table public.ergebnisse enable row level security;
alter table public.fragen     enable row level security;
alter table public.antworten  enable row level security;

-- Testseite: schreibt nicht direkt in die Tabellen, sondern nur über die
-- Funktion test_speichern (Abschnitt 5). Alte Regeln entfernen, falls vorhanden:
drop policy if exists "Test legt Sitzung an"     on public.sitzungen;
drop policy if exists "Test speichert Ereignis"  on public.ereignisse;
drop policy if exists "Test speichert Ergebnis"  on public.ergebnisse;
drop policy if exists "Test speichert Antwort"   on public.antworten;

-- Testseite: liest die aktiven Fragen (Admins sehen alle)
drop policy if exists "Fragen lesen" on public.fragen;
create policy "Fragen lesen" on public.fragen for select to anon, authenticated
  using (aktiv or public.ist_admin());

-- Admin: lesen und löschen
drop policy if exists "Admin liest Sitzungen"    on public.sitzungen;
drop policy if exists "Admin löscht Sitzungen"   on public.sitzungen;
drop policy if exists "Admin liest Ereignisse"   on public.ereignisse;
drop policy if exists "Admin löscht Ereignisse"  on public.ereignisse;
drop policy if exists "Admin liest Ergebnisse"   on public.ergebnisse;
drop policy if exists "Admin löscht Ergebnisse"  on public.ergebnisse;
drop policy if exists "Admin liest Antworten"    on public.antworten;
drop policy if exists "Admin löscht Antworten"   on public.antworten;
create policy "Admin liest Sitzungen"   on public.sitzungen  for select to authenticated using (public.ist_admin());
create policy "Admin löscht Sitzungen"  on public.sitzungen  for delete to authenticated using (public.ist_admin());
create policy "Admin liest Ereignisse"  on public.ereignisse for select to authenticated using (public.ist_admin());
create policy "Admin löscht Ereignisse" on public.ereignisse for delete to authenticated using (public.ist_admin());
create policy "Admin liest Ergebnisse"  on public.ergebnisse for select to authenticated using (public.ist_admin());
create policy "Admin löscht Ergebnisse" on public.ergebnisse for delete to authenticated using (public.ist_admin());
create policy "Admin liest Antworten"   on public.antworten  for select to authenticated using (public.ist_admin());
create policy "Admin löscht Antworten"  on public.antworten  for delete to authenticated using (public.ist_admin());

-- Admin: Fragenkatalog bearbeiten
drop policy if exists "Admin legt Fragen an" on public.fragen;
drop policy if exists "Admin ändert Fragen"  on public.fragen;
drop policy if exists "Admin löscht Fragen"  on public.fragen;
create policy "Admin legt Fragen an" on public.fragen for insert to authenticated with check (public.ist_admin());
create policy "Admin ändert Fragen"  on public.fragen for update to authenticated using (public.ist_admin()) with check (public.ist_admin());
create policy "Admin löscht Fragen"  on public.fragen for delete to authenticated using (public.ist_admin());

-- Die Admin-Liste ist über die Webseite gar nicht erreichbar
revoke all on public.admins from anon, authenticated;

-- Rechte ausdrücklich setzen (die Regeln oben schränken sie weiter ein)
grant usage on schema public to anon, authenticated;
grant select on public.fragen to anon, authenticated;
grant insert, update, delete on public.fragen to authenticated;
grant select, delete on public.sitzungen, public.ereignisse, public.ergebnisse, public.antworten to authenticated;


-- 5. Speichern für die Testseite ---------------------------------------
-- Nimmt Sitzung, Ereignisse, Ergebnis und Antworten in einem Aufruf
-- entgegen. Doppelt gesendete Einträge werden ignoriert, fehlerhafte
-- einzeln übersprungen. Die Uhrzeit setzt immer der Server.
create or replace function public.test_speichern(daten jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  r jsonb;
  ok integer := 0;
  fehler integer := 0;
begin
  if daten is null or jsonb_typeof(daten) <> 'object' or pg_column_size(daten) > 500000 then
    raise exception 'Ungültige Daten';
  end if;

  for r in select value from jsonb_array_elements(coalesce(daten -> 'sitzungen', '[]'::jsonb)) limit 5 loop
    begin
      insert into public.sitzungen
        select (jsonb_populate_record(null::public.sitzungen, r || jsonb_build_object('erstellt', now()))).*
        on conflict (id) do nothing;
      ok := ok + 1;
    exception when others then fehler := fehler + 1;
    end;
  end loop;

  for r in select value from jsonb_array_elements(coalesce(daten -> 'ereignisse', '[]'::jsonb)) limit 500 loop
    begin
      insert into public.ereignisse
        select (jsonb_populate_record(null::public.ereignisse,
                jsonb_build_object('daten', '{}'::jsonb) || r || jsonb_build_object('erstellt', now()))).*
        on conflict (id) do nothing;
      ok := ok + 1;
    exception when others then fehler := fehler + 1;
    end;
  end loop;

  for r in select value from jsonb_array_elements(coalesce(daten -> 'ergebnisse', '[]'::jsonb)) limit 5 loop
    begin
      insert into public.ergebnisse
        select (jsonb_populate_record(null::public.ergebnisse, r || jsonb_build_object('erstellt', now()))).*
        on conflict (sitzung_id) do nothing;
      ok := ok + 1;
    exception when others then fehler := fehler + 1;
    end;
  end loop;

  for r in select value from jsonb_array_elements(coalesce(daten -> 'antworten', '[]'::jsonb)) limit 100 loop
    begin
      insert into public.antworten
        select (jsonb_populate_record(null::public.antworten, r || jsonb_build_object('erstellt', now()))).*
        on conflict (id) do nothing;
      ok := ok + 1;
    exception when others then fehler := fehler + 1;
    end;
  end loop;

  return jsonb_build_object('gespeichert', ok, 'fehler', fehler);
end;
$$;
revoke all on function public.test_speichern(jsonb) from public;
grant execute on function public.test_speichern(jsonb) to anon, authenticated;


-- 6. Startfragen (kannst du danach auf der Admin-Seite ändern) --------
-- Nur beim ersten Ausführen: Bei erneutem Ausführen bleiben deine Fragen unverändert.
insert into public.fragen (position, typ, frage, optionen, pflicht, schluessel)
select v.position, v.typ, v.frage, v.optionen, v.pflicht, v.schluessel
from (values
  (1, 'einfach',  'Würdest du Campi installieren, wenn deine Hochschule die App anbietet?',
      array['Ja, sicher', 'Eher ja', 'Eher nein', 'Nein'], true, 'installieren'),
  (2, 'mehrfach', 'Was würde Campi für dich ersetzen?',
      array['Mensa-App oder -Website', 'Website der Hochschule', 'Campus-Portal', 'Lageplan',
            'Gruppenchats für Infos', 'Stadt- oder Event-Apps', 'Nichts davon'], true, 'ersetzt'),
  (3, 'einfach',  'Was ist dir an Campi am wichtigsten?',
      array['Raumsuche', 'Mensa', 'KI-Assistent', 'Fristen und Kontakte', 'Stadtleben'], true, 'wichtigste'),
  (4, 'text',     'Was fehlt dir oder hat dich gestört?', array[]::text[], false, 'kommentar')
) as v(position, typ, frage, optionen, pflicht, schluessel)
where not exists (select 1 from public.fragen);


-- 7. DEINE ADMIN-E-MAIL ------------------------------------------------
--    Dieselbe E-Mail, mit der du unter Authentication > Users einen
--    Benutzer anlegst. Zwischen den Anführungszeichen ersetzen:
insert into public.admins (email) values (lower('deine-email@beispiel.de'))
on conflict do nothing;
