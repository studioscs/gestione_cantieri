# Gestione cantieri — istruzioni per Claude

Gestionale web per la Direzione Lavori (Studio Tecnico SCS): cantieri, giornale
lavori, ODS, sospensioni/proroghe, varianti, SAL, verbali, prelievi, accettazione
materiali, collaudo e sicurezza (CSE). Utente: ingegnere DL italiano.

## Regole di lavoro (preferenze dell'utente)
- **Rispondere sempre in italiano**, in modo chiaro e senza gergo informatico.
- Flusso standard per ogni richiesta: modifica → commit sul branch di lavoro →
  push → PR → **squash merge su `main` fatto da Claude** (l'utente lo chiede
  sempre: "fai tu il merge su main"). Poi attendere la pubblicazione su GitHub
  Pages e dire all'utente di ricaricare la pagina.
- Ad ogni modifica aggiornare `APP_VERSIONE` (formato `AAAA.MM.GGx`, es.
  `2026.11.02a`; la lettera cresce nello stesso giorno). È mostrata nell'app ed
  è il modo con cui l'utente verifica di avere la versione nuova.
- Prima di pubblicare: controllo sintassi di tutti gli `<script>` e, quando la
  modifica riguarda interfaccia o PDF, prova nel browser (vedi "Come provare").
- **Non archiviare copie di documenti/PDF su Supabase** (spazio limitato): nel
  database si registrano solo i metadati (chi ha firmato, quando), mai immagini
  delle firme o file.
- Eliminando un cantiere devono sparire anche tutti i suoi dati collegati.

## Architettura
- **Tutta l'app è in un solo file: `index.html`** (~13.000 righe, HTML + CSS +
  JS senza build). Pubblicata con GitHub Pages dal branch `main`
  (https://studioscs.github.io/gestione_cantieri/).
- Backend: **Supabase** (Postgres + Auth + RLS), client JS da CDN
  (`@supabase/supabase-js@2`), oggetto globale `sb` (esposto anche su
  `window.sb` per le finestre dei documenti firmabili).
- Navigazione: `showView(view)` con la mappa `views` (dashboard, cantieri, fasi,
  sospensioni, varianti, giornale, ods, comunicazioni, verbali, prelievi,
  materiali, provecollaudo, liste, sal, ditte, team, report, studio).
- Modali: `openModal(titolo, html)` / `closeModal()`.
- Escape: `esc()` NON scappa le virgolette: per valori in attributi usare
  `cseA()` (o evitare `"` negli attributi).

### Ruoli e permessi
- Ruolo per cantiere in `cantiere_utenti.ruolo` (enum `ruolo_cantiere`):
  `dl, do, rup, dt_impresa, committente, cse, collaudatore`.
- `cantiere_utenti.anche_cse`: un DL/DO può svolgere **anche** il ruolo di CSE.
- Lato app: `ROLE_PERMS`, `can(p)`, `isCSE()`, `puoCreareVerbali()`,
  `puoGestireVerbale(tipo)`, `limitaTipiVerbale(prefix)`. La sicurezza vera è
  nelle policy RLS.
- **Verbali: li crea/modifica/elimina solo chi li redige** — tipi `cse_*` solo
  il CSE (ruolo `cse` o `anche_cse`); tutti gli altri DL e DO; i verbali di
  collaudo (`collaudo_statico`, `certificato_collaudo_statico`) anche il
  collaudatore. Funzione DB `puo_gestire_verbale(cantiere, tipo)` + policy.
- RUP/committente annotano i verbali solo con la funzione
  `annota_verbale_rup(id, nota)`.
- Collaudatore: stessa visibilità del RUP, scrive solo i verbali di collaudo.

### Verbali (tabella `verbali`, dati strutturati in `dati_extra` jsonb)
Per aggiungere un tipo di verbale servono, in `index.html`:
`tipoIcon`/`tipoLabel` (in `renderVerbali`), le `<option>` in
`openModalNuovoVerbale` e `openModalEditVerbale`, `tipoL` in `salvaVerbale`,
`VERBALE_FILE_CODE`, `TIPI_STRUTTURATI` in `toggleVerbaleExtra`, la funzione
`extraFields…Html(prefix, dx, …)` (box con id `${prefix}_extra_${tipo}`),
la raccolta dati in `raccogliDatiExtraVerbale`, il ramo in
`apriVerbaleFirmabile` (titolo, normativa, corpo, metaRows) e i firmatari
(`firmatariDefaultMap`, `FIRMATARI_DA_DOCUMENTO`).
- Verbali della sicurezza: array `CSE_VERBALI` (7 tipi `cse_*`), funzioni
  `extraFieldsCseHtml`, `raccogliDatiCse`, `bodyCse`, `firmatariCse`.
- Constatazione: apertura automatica (data in lettere, ora, presenti) +
  "Si constata che" / "Si dispone che".
- Duplica verbale: `openModalEditVerbale(id, true)`.
- Ogni verbale/prelievo crea in automatico la riga nel giornale lavori
  (`annotaGiornale`).

### Documenti firmabili e PDF
- Motore unico `apriDocumentoFirmabile(opts)`: carta intestata degli studi
  (anche più studi in RTP, con loghi e marchi di certificazione), titolo,
  "COMUNE DI …" (`comuneCantiere(c)` — il comune, mai l'indirizzo), righe meta,
  corpo, luogo e data, riquadri firma alti, "Firmato il" = data del documento.
- Script della finestra: `PDF_ENGINE_JS` (dentro un template literal: nei testi
  usare `\\n` raddoppiati). "Salva firme nel gestionale" aggiorna `firmatari` e
  `pdf_generato_at` del record e **mostra l'esito in una finestra disegnata
  nella pagina** (`finestraEsito`): non usare `alert`/`confirm`, Safari su
  iPad/Mac li sopprime.
- Nome file: `nomeFileVerbale(c, data, codice, numero)` →
  `CODICECOMMESSA_aammgg_CODICE` (es. `2025_02_261021_VERPREL_ACC`), usando
  `cantieri.codice_commessa`.
- Luogo: `luogoCantiere(c)` (indirizzo — comune); presenti di default solo DL
  e DT impresa (`PRESENTI_DEFAULT_RUOLI`); nei verbali CSE il CSE e il
  responsabile della ditta.

### Altre sezioni
- Prelievi (`verbali_prelievo`, config `PRELIEVO_TIPI` con `cols` per tipo:
  bulloni, saldature con Tab. 24 UNI EN 1090-2, barre, carpenteria, reti, cls,
  malta, muratura, FRP, FRCM, CRM, generico). Colonne: `label`, `th` (intest.
  breve nel PDF), `hint`, `placeholder`, `type` (select/datalist), `opzionale`
  (colonna PDF solo se compilata), `vuoto` (testo se vuota, es. "da acquisire").
- Accettazione materiali (`accettazione_materiali`): elenco standard, stati,
  richieste successive su rifiuto, verbale di esame firmato solo dal DL.
- Programma prove di collaudo (All. II.14 art. 1): `PROVE_COLLAUDO`, Parte A
  controlli NTC cap. 11, Parte B impianti, prove duplicabili.
- RSU (relazione a struttura ultimata), collaudo statico e certificato art. 67.
- Conteggio giorni contrattuali: sospensioni, riprese, proroghe (una proroga
  non sospende i lavori).

## Supabase
- Progetto usato dall'app: **SCS - gestionale cantiere DL**, ref
  `kdshrvsaecdbcfpsoggz` (regione eu-north-1). L'altro progetto `scs-gestionale`
  non è collegato all'app: non toccarlo.
- Tabelle: profiles, cantieri, cantiere_utenti, fasi, ods, ods_log,
  giornale_lavori, giornale_log, comunicazioni, sal, sal_log, ditte,
  sospensioni, varianti, verbali, verbali_prelievo, liste_settimanali,
  liste_righe, accettazione_materiali. RLS attiva su tutte.
- Funzioni: `e_membro`, `e_dl`, `my_role`, `is_collaudatore`,
  `puo_gestire_verbale`, `annota_verbale_rup`, `aggiungi_membro_cantiere`,
  `crea_cantiere`, trigger di log su giornale/ods/sal.
- **Migrazioni**: salvare sempre il file in `sql/AAAA-MM-GG-descrizione.sql`
  (idempotente: `if not exists`, `drop policy if exists`…). Poi:
  - aggiunte non distruttive (colonne, tabelle, funzioni) → applicarle con il
    connettore Supabase (`apply_migration`) e verificare con una query;
  - migrazioni con `drop` o sostituzioni → il connettore chiede una conferma
    che in questa interfaccia non arriva all'utente: **dare direttamente il
    testo SQL da incollare nel SQL Editor**, poi verificare.
  - Se il connettore non è disponibile: dare il testo da incollare.
- `cantiere_utenti.ruolo` è un enum: nelle policy confrontare `ruolo::text`
  (un valore enum appena aggiunto non è usabile nella stessa transazione,
  errore 55P04).
- Gli aggiornamenti bloccati da RLS non danno errore ma non aggiornano righe:
  usare `.select('id')` e controllare che torni almeno una riga.

## Come provare (senza toccare i dati veri)
- Chromium + Playwright sono disponibili: `require('/opt/node22/lib/node_modules/playwright')`,
  `executablePath: '/opt/pw-browsers/chromium'`.
- Prova completa dell'app: aprire `file:///…/index.html` intercettando lo script
  CDN di Supabase (`context.route('**/supabase-js@2*', …)`) con un finto client
  che risponde ai `from().select()/update()`; poi chiamare le funzioni (es.
  `apriDocumentoFirmabile`) e cliccare i pulsanti.
- Prove mirate: estrarre da `index.html` solo le funzioni interessate in una
  pagina di prova nella cartella temporanea.
- Sul database solo query di lettura; per provare le policy usare un blocco
  `do $$ … raise exception … $$` che annulla tutto.
- Controllo sintassi: `node -e` che esegue `new Function()` su ogni `<script>`.
