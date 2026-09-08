-- ============================================================
-- Marchi delle certificazioni possedute dagli studi
-- Da eseguire nel SQL Editor di Supabase, dopo 2026-09-08-loghi-studi.sql.
-- Idempotente: rieseguirla non fa danni.
-- ============================================================

-- Array di oggetti {sigla, logo}:
--   sigla → testo mostrato nel piè di pagina (es. "ISO 9001:2015")
--   logo  → data URI PNG del marchio, già ridimensionato lato client
--           a circa 200x120 px, quindi di pochi KB ciascuno.
-- I marchi compaiono a destra nella testata dei documenti, raccolti da
-- tutti gli studi in intestazione; l'attribuzione allo studio che li
-- possiede è nel piè di pagina e nel title dell'immagine.
alter table public.profiles
  add column if not exists studio_certificazioni jsonb;

comment on column public.profiles.studio_certificazioni is
  'Certificazioni dello studio: array di {sigla, logo}. logo e'' un data URI PNG ridimensionato lato client.';
