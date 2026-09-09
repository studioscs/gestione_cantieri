-- ============================================================
-- Promemoria "richiesta prove inviata al laboratorio" sui verbali
-- di prelievo. Da eseguire nel SQL Editor di Supabase. Idempotente.
-- ============================================================
alter table public.verbali_prelievo
  add column if not exists richiesta_prove_inviata boolean not null default false,
  add column if not exists richiesta_prove_data    date;

comment on column public.verbali_prelievo.richiesta_prove_inviata is
  'Spunta di promemoria: la richiesta di prove è stata inviata al laboratorio (indipendente da firme/PDF).';
comment on column public.verbali_prelievo.richiesta_prove_data is
  'Data in cui è stata spuntata la richiesta prove inviata; azzerata se la spunta viene rimossa.';
