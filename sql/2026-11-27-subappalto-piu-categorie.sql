-- ============================================================
-- Subappalto su piu' categorie di opere
-- Una ditta subappaltatrice puo' eseguire lavorazioni di piu' categorie
-- (es. OG1 e OS30), ciascuna con il proprio importo:
--   ditte.subappalto_categorie = [{"categoria":"OG1","importo":120000},
--                                 {"categoria":"OS30","importo":30000}]
-- importo_affidato resta il totale (somma delle categorie) e
-- categoria_subappalto l'elenco leggibile ("OG1, OS30"): le ditte inserite
-- prima, con una sola categoria, continuano a funzionare.
-- Solo aggiunta di colonna: idempotente. Nessuna nuova tabella, quindi
-- copia di sicurezza e ripristino non vanno toccati.
-- ============================================================
alter table public.ditte
  add column if not exists subappalto_categorie jsonb not null default '[]'::jsonb;

comment on column public.ditte.subappalto_categorie is 'Categorie del subappalto con importo: [{categoria, importo}].';
