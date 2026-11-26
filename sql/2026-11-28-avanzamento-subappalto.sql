-- ============================================================
-- Subappalto: avanzamento dei lavori eseguiti dalla ditta (al SAL)
-- Per confrontare le ore registrate nel giornale con la manodopera di
-- progetto delle quantita' effettivamente eseguite (non con il totale):
--   ditte.avanzamento_subappalto = {"sal_numero":2, "data":"2026-10-31",
--     "righe":[{"categoria":"OS3","importo":20000}, ...]}
-- importo = lavori eseguiti dalla ditta contabilizzati al SAL, ai prezzi
-- contrattuali (netti). La manodopera di progetto della quota eseguita e'
-- importo / (1 - ribasso) x incidenza della manodopera della categoria.
-- Solo aggiunta di colonna: idempotente. Nessuna nuova tabella, quindi
-- copia di sicurezza e ripristino non vanno toccati.
-- ============================================================
alter table public.ditte
  add column if not exists avanzamento_subappalto jsonb;

comment on column public.ditte.avanzamento_subappalto is 'Lavori eseguiti dalla ditta al SAL di riferimento: {sal_numero, data, righe:[{categoria, importo}]} (prezzi contrattuali).';
