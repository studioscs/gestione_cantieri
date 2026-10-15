-- ============================================================
-- Ruolo "collaudatore" (collaudatore statico / tecnico-amministrativo)
-- Stessa visibilità del RUP; in scrittura solo i verbali di collaudo:
--   collaudo_statico              (verbale di visita di collaudo)
--   certificato_collaudo_statico  (certificato art. 67 D.P.R. 380/2001)
-- Da eseguire nel SQL Editor di Supabase. Idempotente.
-- ============================================================

-- 1) Ammette il nuovo valore nella colonna cantiere_utenti.ruolo.
--    Gestisce sia il caso di colonna testo con vincolo CHECK, sia quello
--    di colonna di tipo enum.
do $$
declare
  r record;
  tipo_col regtype;
begin
  select a.atttypid::regtype into tipo_col
  from pg_attribute a
  where a.attrelid = 'public.cantiere_utenti'::regclass and a.attname = 'ruolo';

  if exists (select 1 from pg_type t where t.oid = tipo_col and t.typtype = 'e') then
    execute format('alter type %s add value if not exists %L', tipo_col, 'collaudatore');
  else
    -- rimuove i vincoli CHECK esistenti sul ruolo e li ricrea con il nuovo valore
    for r in
      select conname from pg_constraint
      where conrelid = 'public.cantiere_utenti'::regclass
        and contype = 'c'
        and pg_get_constraintdef(oid) ilike '%ruolo%'
    loop
      execute format('alter table public.cantiere_utenti drop constraint %I', r.conname);
    end loop;
    alter table public.cantiere_utenti
      add constraint cantiere_utenti_ruolo_check
      check (ruolo in ('dl','rup','dt_impresa','do','committente','cse','collaudatore'))
      not valid;
  end if;
end $$;

-- 2) Funzione di supporto: l'utente è collaudatore di quel cantiere?
create or replace function public.is_collaudatore(p_cantiere text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.cantiere_utenti
    where cantiere_id::text = p_cantiere
      and utente_id = auth.uid()
      and ruolo = 'collaudatore'
  );
$$;

-- 3) Regole RLS aggiuntive sui verbali: il collaudatore può inserire e
--    modificare SOLO i verbali di collaudo del proprio cantiere, e non può
--    trasformarli in altri tipi. Nessuna regola di cancellazione.
--    Sono regole "permissive": si sommano a quelle esistenti per DL/DO
--    senza toccarle.
drop policy if exists verbali_collaudatore_insert on public.verbali;
create policy verbali_collaudatore_insert on public.verbali
  for insert
  with check (
    public.is_collaudatore(cantiere_id::text)
    and tipo in ('collaudo_statico','certificato_collaudo_statico')
  );

drop policy if exists verbali_collaudatore_update on public.verbali;
create policy verbali_collaudatore_update on public.verbali
  for update
  using (
    public.is_collaudatore(cantiere_id::text)
    and tipo in ('collaudo_statico','certificato_collaudo_statico')
  )
  with check (
    public.is_collaudatore(cantiere_id::text)
    and tipo in ('collaudo_statico','certificato_collaudo_statico')
  );
