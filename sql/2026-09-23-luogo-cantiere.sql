-- ============================================================
-- Comune e indirizzo del cantiere, per precompilare il luogo nei
-- verbali invece di ripiegare sulla stazione appaltante (che è
-- l'ente committente, non il posto dove si lavora).
-- Da eseguire nel SQL Editor di Supabase. Idempotente.
-- ============================================================
alter table public.cantieri
  add column if not exists comune    text,
  add column if not exists indirizzo text;

comment on column public.cantieri.comune is
  'Comune in cui si trova il cantiere; usato per l''intestazione "COMUNE DI …" dei documenti.';
comment on column public.cantieri.indirizzo is
  'Indirizzo o località del cantiere; precompila i campi "luogo" / "cantiere sito in" dei verbali.';
