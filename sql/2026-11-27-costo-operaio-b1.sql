-- ============================================================
-- Costo orario dell'operaio specializzato B1 (impianti, fabbri: ditte
-- non edili), per il controllo dei subappalti. Solo aggiunta: idempotente.
-- ============================================================
alter table public.cantieri
  add column if not exists costo_ora_b1 numeric;

comment on column public.cantieri.costo_ora_b1 is 'Costo orario contrattuale operaio specializzato B1 (impianti, fabbri — ditte non edili), EUR/h.';
