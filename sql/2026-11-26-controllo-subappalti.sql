-- ============================================================
-- Controllo subappalti / subaffidamenti
-- 1) cantiere: costo orario contrattuale degli operai (comune, qualificato,
--    specializzato) e ore lavorative giornaliere di riferimento
-- 2) ditte subappaltatrici/subaffidatarie: importo autorizzato, lavorazioni
--    autorizzate (una per riga) ed estremi dell'autorizzazione
-- Le presenze nel giornale (giornale_lavori.maestranze, jsonb) ricevono per
-- ogni riga livello, ore e lavorazione svolta: nessuna colonna da aggiungere.
-- Solo aggiunte: idempotente.
-- ============================================================
alter table public.cantieri
  add column if not exists costo_ora_comune        numeric,
  add column if not exists costo_ora_qualificato   numeric,
  add column if not exists costo_ora_specializzato numeric,
  add column if not exists ore_giornaliere         numeric default 8;

alter table public.ditte
  add column if not exists importo_affidato        numeric,
  add column if not exists lavorazioni_affidate    text,
  add column if not exists estremi_autorizzazione  text;

comment on column public.cantieri.costo_ora_comune is 'Costo orario contrattuale operaio comune (EUR/h), per il controllo dei subappalti.';
comment on column public.ditte.importo_affidato is 'Importo del subappalto/subaffidamento comunicato o autorizzato (EUR).';
comment on column public.ditte.lavorazioni_affidate is 'Lavorazioni comunicate/autorizzate, una per riga.';
