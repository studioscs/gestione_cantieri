-- ============================================================
-- Permessi sui verbali: li crea, modifica ed elimina solo chi li redige
--   * verbali della sicurezza (tipo cse_*)  -> CSE (ruolo cse oppure
--     membro con anche_cse, es. DL o DO che e' anche coordinatore)
--   * tutti gli altri verbali               -> DL e DO
--   * verbali di collaudo                   -> anche il collaudatore
-- Lettura invariata: tutti i membri del cantiere.
-- L'annotazione del RUP/committente passa da una funzione dedicata che
-- scrive solo il campo note_rup.
-- Sostituisce le regole precedenti (verbali_ins/upd/del, che ammettevano
-- qualunque membro, e verbali_collaudatore_*). Idempotente.
-- ============================================================

create or replace function public.puo_gestire_verbale(p_cantiere uuid, p_tipo text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.cantiere_utenti cu
    where cu.cantiere_id = p_cantiere
      and cu.utente_id = auth.uid()
      and (
        case when p_tipo like 'cse\_%'
          then cu.ruolo::text = 'cse' or cu.anche_cse
          else cu.ruolo::text in ('dl','do')
               or (cu.ruolo::text = 'collaudatore'
                   and p_tipo in ('collaudo_statico','certificato_collaudo_statico'))
        end
      )
  );
$$;

drop policy if exists verbali_ins on public.verbali;
drop policy if exists verbali_upd on public.verbali;
drop policy if exists verbali_del on public.verbali;
drop policy if exists verbali_collaudatore_insert on public.verbali;
drop policy if exists verbali_collaudatore_update on public.verbali;

create policy verbali_ins on public.verbali
  for insert with check (public.puo_gestire_verbale(cantiere_id, tipo));

-- using: il verbale com'e' ora; with check: come diventa (non si puo'
-- trasformare un verbale in un tipo che non si ha titolo a redigere)
create policy verbali_upd on public.verbali
  for update using (public.puo_gestire_verbale(cantiere_id, tipo))
  with check (public.puo_gestire_verbale(cantiere_id, tipo));

create policy verbali_del on public.verbali
  for delete using (public.puo_gestire_verbale(cantiere_id, tipo));

-- Annotazione del RUP / committente: aggiorna solo note_rup
create or replace function public.annota_verbale_rup(p_id uuid, p_nota text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.verbali v
    join public.cantiere_utenti cu on cu.cantiere_id = v.cantiere_id
    where v.id = p_id and cu.utente_id = auth.uid()
      and cu.ruolo::text in ('rup','committente')
  ) then
    raise exception 'Solo il RUP o il committente possono annotare il verbale';
  end if;
  update public.verbali set note_rup = nullif(trim(p_nota), '') where id = p_id;
end;
$$;

revoke all on function public.annota_verbale_rup(uuid, text) from public;
grant execute on function public.annota_verbale_rup(uuid, text) to authenticated;
