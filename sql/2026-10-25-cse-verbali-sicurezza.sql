-- ============================================================
-- Verbali della sicurezza a carico del CSE
-- 1) un membro del team (tipicamente il DL o un DO) puo' svolgere anche
--    il ruolo di Coordinatore per l'esecuzione: flag anche_cse
-- 2) dati anagrafici del professionista, riportati nelle lettere e nei
--    verbali ("Il sottoscritto Ing. …, nato a … il …, residente a …")
-- I verbali CSE stanno nella tabella verbali (tipi cse_*): nessuna nuova
-- tabella. Da eseguire nel SQL Editor di Supabase. Idempotente.
-- ============================================================
alter table public.cantiere_utenti
  add column if not exists anche_cse boolean not null default false;

comment on column public.cantiere_utenti.anche_cse is
  'Il membro svolge anche il ruolo di Coordinatore per la sicurezza in fase di esecuzione (oltre al proprio ruolo).';

alter table public.profiles
  add column if not exists titolo        text,
  add column if not exists luogo_nascita text,
  add column if not exists data_nascita  date,
  add column if not exists residenza     text;

comment on column public.profiles.titolo is 'Titolo professionale anteposto al nome (es. Ing., Dott. Arch., Geom.).';
comment on column public.profiles.residenza is 'Comune e indirizzo di residenza, per le dichiarazioni del professionista.';
