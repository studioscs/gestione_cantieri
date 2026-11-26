-- ============================================================
-- Limiti del subappalto concessi a contratto
-- 1) cantiere: limite complessivo (% dell'importo contrattuale, facoltativo)
--    e categorie subappaltabili con importo della categoria e percentuale
--    massima subappaltabile (0 = non subappaltabile), in jsonb:
--    [{"categoria":"OG1","descrizione":"Edifici civili","importo":1000000,"perc":50}]
-- 2) ditta subappaltatrice: categoria a cui si riferisce il subappalto
-- Con questi dati l'app verifica l'importo autorizzato e la manodopera
-- registrata nel giornale rispetto al limite di ogni categoria.
-- Solo aggiunte di colonne: idempotente. Nessuna nuova tabella, quindi
-- copia di sicurezza e ripristino non vanno toccati (ripristina_righe
-- prende le colonne dal file).
-- ============================================================
alter table public.cantieri
  add column if not exists subappalto_limite_perc numeric,
  add column if not exists subappalto_categorie   jsonb not null default '[]'::jsonb;

alter table public.ditte
  add column if not exists categoria_subappalto text;

comment on column public.cantieri.subappalto_limite_perc is 'Limite complessivo del subappalto da contratto, in % dell''importo contrattuale (facoltativo).';
comment on column public.cantieri.subappalto_categorie is 'Categorie subappaltabili: [{categoria, descrizione, importo, perc}] (perc 0 = non subappaltabile).';
comment on column public.ditte.categoria_subappalto is 'Categoria (es. OG1, OS30) a cui si riferisce il subappalto.';
