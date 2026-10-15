-- ============================================================
-- Accettazione materiali: esito "respinta con richiesta di
-- integrazioni" e firme del verbale di esame della documentazione.
-- Da eseguire nel SQL Editor di Supabase, dopo
-- 2026-10-15-accettazione-materiali.sql. Idempotente.
-- ============================================================

-- 1) Nuovo stato 'integrazione' ammesso nella colonna stato
do $$
declare r record;
begin
  for r in
    select conname from pg_constraint
    where conrelid = 'public.accettazione_materiali'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%stato%'
  loop
    execute format('alter table public.accettazione_materiali drop constraint %I', r.conname);
  end loop;
end $$;

alter table public.accettazione_materiali
  add constraint accettazione_materiali_stato_check
  check (stato in ('da_richiedere','richiesta','accettata','rifiutata','integrazione','non_pertinente'));

-- 2) Firme del verbale (stesse colonne degli altri verbali firmabili)
alter table public.accettazione_materiali
  add column if not exists firmatari       jsonb,
  add column if not exists pdf_generato_at timestamptz;
