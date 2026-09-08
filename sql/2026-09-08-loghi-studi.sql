-- ============================================================
-- Loghi e dati degli studi in carta intestata (anche RTP / più DL)
-- Da eseguire nel SQL Editor di Supabase.
-- Le colonne sono aggiunte in modo idempotente: rieseguire non fa danni.
-- ============================================================

-- 1) Scheda studio sul profilo di ciascun professionista.
--    studio_logo contiene un data URI PNG già ridimensionato lato client
--    (circa 320x120 px), quindi resta nell'ordine di poche decine di KB.
alter table public.profiles
  add column if not exists studio_denominazione  text,
  add column if not exists studio_sede_legale    text,
  add column if not exists studio_sede_operativa text,
  add column if not exists studio_piva           text,
  add column if not exists studio_email          text,
  add column if not exists studio_web            text,
  add column if not exists studio_logo           text;

-- 2) Quali studi compaiono in testata di un dato cantiere, e in che ordine.
--    Array di id utente; il primo elemento è la mandataria del raggruppamento.
--    NULL = tutti i DL/DO del cantiere che hanno compilato la scheda studio.
alter table public.cantieri
  add column if not exists studi_intestazione jsonb;

comment on column public.cantieri.studi_intestazione is
  'Array di utente_id degli studi da mostrare in carta intestata, in ordine; il primo e'' la mandataria. NULL = automatico (tutti i DL/DO con scheda studio).';

-- 3) I membri di un cantiere devono poter leggere la scheda studio dei
--    colleghi, altrimenti la carta intestata resterebbe vuota per tutti
--    tranne che per il proprietario del profilo.
--    Esegui questo blocco SOLO se la lettura dei profili altrui non è già
--    consentita da una policy esistente (in tal caso da' errore di duplicato,
--    che puoi ignorare).
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename  = 'profiles'
      and policyname = 'profili_leggibili_dai_membri_dei_miei_cantieri'
  ) then
    create policy profili_leggibili_dai_membri_dei_miei_cantieri
      on public.profiles for select
      using (
        id = auth.uid()
        or exists (
          select 1
          from public.cantiere_utenti mio
          join public.cantiere_utenti altro
            on altro.cantiere_id = mio.cantiere_id
          where mio.utente_id = auth.uid()
            and altro.utente_id = public.profiles.id
        )
      );
  end if;
end $$;
