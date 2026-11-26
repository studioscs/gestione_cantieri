-- ============================================================
-- Subappalto: sicurezza compresa nei prezzi distinta dagli oneri speciali
-- I costi della sicurezza dichiarati nei subappalti sono quasi sempre quelli
-- COMPRESI NEI PREZZI delle lavorazioni: seguono il ribasso come il resto e
-- non entrano nel calcolo della manodopera minima (dato facoltativo,
-- informativo) -> ditte.sicurezza_inclusa_subappalto.
-- ditte.oneri_sicurezza_subappalto resta SOLO per i lavori relativi agli
-- oneri della sicurezza speciali (PSC) affidati in subappalto: sono gli
-- unici non soggetti a ribasso.
-- Solo aggiunta di colonna: idempotente. Nessuna nuova tabella, quindi
-- copia di sicurezza e ripristino non vanno toccati.
-- ============================================================
alter table public.ditte
  add column if not exists sicurezza_inclusa_subappalto numeric;

comment on column public.ditte.sicurezza_inclusa_subappalto is 'Costi della sicurezza compresi nei prezzi delle lavorazioni subappaltate (soggetti a ribasso, facoltativo).';
comment on column public.ditte.oneri_sicurezza_subappalto is 'Lavori relativi agli oneri della sicurezza speciali (PSC) affidati in subappalto: non soggetti a ribasso.';
