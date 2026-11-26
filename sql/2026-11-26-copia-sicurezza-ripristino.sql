-- ============================================================
-- Copia di sicurezza e ripristino
-- ------------------------------------------------------------
-- L'app scarica la copia (tutte le tabelle dei cantieri di cui si e' DL)
-- in un file JSON da salvare sul server dello studio. Per rimetterla serve
-- questa funzione, perche' reinserire le righe dal browser:
--   - farebbe scattare i trigger di registro (giornale_log, ods_log,
--     sal_log), creando righe di registro doppie: i registri vengono gia'
--     ripristinati dalla copia;
--   - per un cantiere cancellato non sarebbe permesso dalle regole RLS,
--     perche' l'utente non e' piu' membro del cantiere.
--
-- public.ripristina_righe(tabella, righe, sovrascrivi):
--   - solo per le tabelle dell'elenco (profiles no: gli utenti stanno
--     nell'accesso di Supabase);
--   - ogni riga deve appartenere a un cantiere di cui chi ripristina e' DL.
--     Eccezioni, per poter rimettere un cantiere cancellato per intero:
--       * cantieri: un cantiere che non esiste piu' si puo' ricreare
--         (come gia' oggi chiunque puo' creare un cantiere);
--       * cantiere_utenti: in un cantiere senza membri si possono rimettere
--         i membri, purche' fra le righe ci sia chi ripristina come DL;
--   - nella stessa transazione spegne i trigger della tabella, inserisce
--     (sovrascrivi = false: le righe gia' presenti restano come sono;
--     true: tornano come nella copia) e li riaccende. Se qualcosa va storto
--     la transazione si annulla e i trigger restano accesi.
--   - non cancella mai niente.
--
-- !! OGNI NUOVA TABELLA DEL GESTIONALE VA AGGIUNTA ANCHE QUI (consentite)
-- !! E IN index.html (TABELLE_COPIA / ORDINE_RIPRISTINO / NOMI_TABELLE_COPIA),
-- !! altrimenti la copia non la contiene e il ripristino la rifiuta.
-- Solo aggiunte: idempotente.
-- ============================================================
create or replace function public.ripristina_righe(tabella text, righe jsonb, sovrascrivi boolean default false)
returns integer language plpgsql security definer set search_path = public as $$
declare
  consentite constant text[] := array['cantieri', 'cantiere_utenti', 'ditte', 'fasi', 'sospensioni',
    'varianti', 'giornale_lavori', 'giornale_log', 'ods', 'ods_log', 'sal', 'sal_log', 'comunicazioni',
    'verbali', 'verbali_prelievo', 'liste_settimanali', 'liste_righe', 'accettazione_materiali'];
  colonne text; aggiorna text; n integer; t record; spenti text[] := '{}'; c uuid;
begin
  if auth.uid() is null then
    raise exception 'Accesso richiesto' using errcode = '42501';
  end if;
  if not (tabella = any(consentite)) then
    raise exception 'Questa tabella non si ripristina: %', tabella using errcode = '22023';
  end if;
  if righe is null or jsonb_typeof(righe) <> 'array' then
    return 0;
  end if;
  select jsonb_agg(e) into righe from jsonb_array_elements(righe) e where jsonb_typeof(e) = 'object';
  if righe is null then
    return 0;
  end if;
  if exists (select 1 from jsonb_array_elements(righe) e where (e ->> 'id') is null) then
    raise exception 'Le righe della copia non hanno la colonna id' using errcode = '22023';
  end if;

  -- ---- permessi, riga per riga ----
  if tabella = 'cantieri' then
    for c in select (e ->> 'id')::uuid from jsonb_array_elements(righe) e loop
      if exists (select 1 from public.cantieri where id = c) and not public.e_dl(c) then
        raise exception 'Non sei il DL del cantiere %: non puoi ripristinarlo', c using errcode = '42501';
      end if;
    end loop;
  else
    if exists (select 1 from jsonb_array_elements(righe) e where (e ->> 'cantiere_id') is null) then
      raise exception 'Righe senza cantiere: non si ripristinano' using errcode = '22023';
    end if;
    for c in select distinct (e ->> 'cantiere_id')::uuid from jsonb_array_elements(righe) e loop
      if public.e_dl(c) then
        continue;
      end if;
      if tabella = 'cantiere_utenti' and public.cantiere_senza_membri(c)
         and exists (select 1 from jsonb_array_elements(righe) e
                      where (e ->> 'cantiere_id')::uuid = c
                        and (e ->> 'utente_id')::uuid = auth.uid()
                        and e ->> 'ruolo' = 'dl') then
        continue;
      end if;
      raise exception 'Non sei il DL del cantiere %: non puoi ripristinarne i dati', c using errcode = '42501';
    end loop;
  end if;

  -- colonne della tabella presenti nel file (le calcolate no): una colonna
  -- aggiunta dopo la copia prende il suo valore predefinito
  select string_agg(quote_ident(col.column_name), ', ' order by col.ordinal_position),
         string_agg(format('%1$I = excluded.%1$I', col.column_name), ', ' order by col.ordinal_position)
           filter (where col.column_name <> 'id')
    into colonne, aggiorna
    from information_schema.columns col
   where col.table_schema = 'public' and col.table_name = tabella
     and col.is_generated = 'NEVER'
     and (righe -> 0) ? col.column_name;

  for t in select tgname from pg_trigger
            where tgrelid = format('public.%I', tabella)::regclass
              and not tgisinternal and tgenabled <> 'D' loop
    execute format('alter table public.%I disable trigger %I', tabella, t.tgname);
    spenti := spenti || t.tgname::text;
  end loop;

  execute format(
    'insert into public.%1$I (%2$s) select %2$s from jsonb_populate_recordset(null::public.%1$I, $1) '
    || 'on conflict (id) do %3$s',
    tabella, colonne,
    case when sovrascrivi and aggiorna is not null
         -- si sovrascrive solo una riga che sta gia' in un cantiere di cui si e' DL:
         -- un file manipolato non puo' spostare righe di altri cantieri
         then format('update set %s where public.e_dl(%I.%I)', aggiorna, tabella,
                     case when tabella = 'cantieri' then 'id' else 'cantiere_id' end)
         else 'nothing' end) using righe;
  get diagnostics n = row_count;

  for t in select unnest(spenti) as tgname loop
    execute format('alter table public.%I enable trigger %I', tabella, t.tgname);
  end loop;
  return n;
end; $$;

revoke all on function public.ripristina_righe(text, jsonb, boolean) from public, anon;
grant execute on function public.ripristina_righe(text, jsonb, boolean) to authenticated;

select 'ripristino da copia' as cosa,
       case when exists (select 1 from pg_proc where proname = 'ripristina_righe') then 'ok' else 'MANCANTE' end as esito;
