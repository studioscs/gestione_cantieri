-- ============================================================
-- Subappalto: manodopera compilata in automatico dal contratto
-- Se la ditta non dichiara i costi della manodopera, il DL puo' compilarli
-- con la manodopera calcolata dalle incidenze di contratto (scheda
-- cantiere). Il flag distingue il valore calcolato da quello dichiarato.
-- Solo aggiunta di colonna: idempotente. Nessuna nuova tabella, quindi
-- copia di sicurezza e ripristino non vanno toccati.
-- ============================================================
alter table public.ditte
  add column if not exists manodopera_calcolata boolean not null default false;

comment on column public.ditte.manodopera_calcolata is 'true = manodopera_subappalto compilata dall''app con le incidenze di contratto (non dichiarata dalla ditta).';
