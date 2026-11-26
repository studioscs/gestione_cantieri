-- ============================================================
-- Costi orari della manodopera per tutti i livelli contrattuali
-- Oltre a comune / qualificato / specializzato / B1 (colonne costo_ora_*,
-- mantenute), il cantiere registra i costi orari di tutte le categorie:
-- operai edili (4° livello, specializzato, qualificato, comune), operai e
-- impiegati metalmeccanici / installazione impianti (D1 ... B1, impiegati
-- fino ad A1), in jsonb:  cantieri.costi_orari = {"quarto": 30.26, "mm_c2": 22.02, ...}
-- I valori NON hanno default: vanno presi dal prezzario/tabelle vigenti.
-- Solo aggiunta di colonna: idempotente. Nessuna nuova tabella, quindi
-- copia di sicurezza e ripristino non vanno toccati.
-- ============================================================
alter table public.cantieri
  add column if not exists costi_orari jsonb not null default '{}'::jsonb;

comment on column public.cantieri.costi_orari is 'Costi orari della manodopera per livello contrattuale (EUR/h), chiavi come LIVELLI_GRUPPI in index.html.';
