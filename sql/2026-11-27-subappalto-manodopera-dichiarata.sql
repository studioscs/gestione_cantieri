-- ============================================================
-- Subappalto: costi della manodopera e della sicurezza dichiarati
-- Art. 119, comma 12, d.lgs. 36/2023: l'affidatario corrisponde al
-- subappaltatore i costi della sicurezza e della manodopera relativi alle
-- prestazioni subappaltate SENZA ALCUN RIBASSO, e la stazione appaltante,
-- sentito il DL, ne verifica l'effettiva applicazione.
-- Per ogni ditta subappaltatrice si registrano quindi, dalla richiesta di
-- autorizzazione / contratto di subappalto, i costi della manodopera e
-- della sicurezza compresi nell'importo del subappalto: l'app confronta la
-- manodopera registrata nel giornale con quella dichiarata.
-- Solo aggiunta di colonne: idempotente. Nessuna nuova tabella, quindi
-- copia di sicurezza e ripristino non vanno toccati.
-- ============================================================
alter table public.ditte
  add column if not exists manodopera_subappalto      numeric,
  add column if not exists oneri_sicurezza_subappalto numeric;

comment on column public.ditte.manodopera_subappalto is 'Costi della manodopera compresi nell''importo del subappalto (art. 119 c.12: senza ribasso).';
comment on column public.ditte.oneri_sicurezza_subappalto is 'Costi della sicurezza compresi nell''importo del subappalto (art. 119 c.12: senza ribasso).';
