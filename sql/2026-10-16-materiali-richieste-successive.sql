-- ============================================================
-- Accettazione materiali: richieste successive dopo un rifiuto.
-- tentativo  = numero della richiesta (1 = prima, 2 = seconda, ...)
-- origine_id = voce rifiutata da cui nasce la richiesta successiva
-- Da eseguire nel SQL Editor di Supabase, dopo
-- 2026-10-15-accettazione-materiali.sql. Idempotente.
-- ============================================================
alter table public.accettazione_materiali
  add column if not exists tentativo  integer not null default 1,
  add column if not exists origine_id uuid references public.accettazione_materiali(id) on delete set null;

create index if not exists accettazione_materiali_origine_idx
  on public.accettazione_materiali (origine_id);
