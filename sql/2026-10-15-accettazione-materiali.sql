-- ============================================================
-- Registro di accettazione dei materiali
-- Una riga per materiale (o per ciascuna versione dello stesso
-- materiale, es. più calcestruzzi), con stato, date e note.
-- Lettura: tutti i membri del cantiere. Scrittura: DL e DO.
-- Da eseguire nel SQL Editor di Supabase. Idempotente.
-- ============================================================

-- 1) Tabella. Il tipo di cantiere_id viene preso da cantieri.id, così la
--    chiave esterna funziona sia con id uuid sia con id numerici.
do $$
declare
  tipo_id text;
begin
  select format_type(a.atttypid, a.atttypmod) into tipo_id
  from pg_attribute a
  where a.attrelid = 'public.cantieri'::regclass and a.attname = 'id';

  execute format($f$
    create table if not exists public.accettazione_materiali (
      id             uuid primary key default gen_random_uuid(),
      cantiere_id    %s not null references public.cantieri(id) on delete cascade,
      categoria      text,
      materiale      text not null,
      specifiche     text,
      stato          text not null default 'da_richiedere'
                     check (stato in ('da_richiedere','richiesta','accettata','rifiutata','non_pertinente')),
      data_richiesta date,
      data_esito     date,
      documenti      jsonb not null default '[]'::jsonb,
      note           text,
      ordine         integer not null default 0,
      created_by     uuid,
      created_at     timestamptz not null default now()
    )$f$, tipo_id);
end $$;

create index if not exists accettazione_materiali_cantiere_idx
  on public.accettazione_materiali (cantiere_id);

-- 2) Sicurezza (RLS)
alter table public.accettazione_materiali enable row level security;

drop policy if exists acc_mat_select on public.accettazione_materiali;
create policy acc_mat_select on public.accettazione_materiali
  for select using (
    exists (select 1 from public.cantiere_utenti cu
            where cu.cantiere_id = accettazione_materiali.cantiere_id
              and cu.utente_id = auth.uid())
  );

drop policy if exists acc_mat_insert on public.accettazione_materiali;
create policy acc_mat_insert on public.accettazione_materiali
  for insert with check (
    exists (select 1 from public.cantiere_utenti cu
            where cu.cantiere_id = accettazione_materiali.cantiere_id
              and cu.utente_id = auth.uid()
              and cu.ruolo::text in ('dl','do'))
  );

drop policy if exists acc_mat_update on public.accettazione_materiali;
create policy acc_mat_update on public.accettazione_materiali
  for update using (
    exists (select 1 from public.cantiere_utenti cu
            where cu.cantiere_id = accettazione_materiali.cantiere_id
              and cu.utente_id = auth.uid()
              and cu.ruolo::text in ('dl','do'))
  ) with check (
    exists (select 1 from public.cantiere_utenti cu
            where cu.cantiere_id = accettazione_materiali.cantiere_id
              and cu.utente_id = auth.uid()
              and cu.ruolo::text in ('dl','do'))
  );

drop policy if exists acc_mat_delete on public.accettazione_materiali;
create policy acc_mat_delete on public.accettazione_materiali
  for delete using (
    exists (select 1 from public.cantiere_utenti cu
            where cu.cantiere_id = accettazione_materiali.cantiere_id
              and cu.utente_id = auth.uid()
              and cu.ruolo::text in ('dl','do'))
  );
