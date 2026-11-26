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
- **Copia di sicurezza e ripristino da tenere SEMPRE allineati (regola
  dell'utente)**: ogni modifica futura che aggiunge o cambia tabelle, o
  colonne che collegano righe fra loro, va riportata anche nel ripristino,
  altrimenti la copia non trova corrispondenza e il ripristino si blocca. In
  pratica, a ogni nuova tabella:
  1. `index.html`: aggiungerla a `ORDINE_RIPRISTINO` (nell'ordine dei
     collegamenti: prima chi è richiamato dagli altri) e a `NOMI_TABELLE_COPIA`;
  2. nuova migrazione `sql/AAAA-MM-GG-….sql` che ricrea
     `public.ripristina_righe` con la tabella nell'elenco `consentite`
     (la tabella deve avere `id` e `cantiere_id`; altrimenti adattare i
     controlli dei permessi nella funzione);
  3. se la tabella richiama sé stessa (come `fasi.parent_id`,
     `accettazione_materiali.origine_id`), ordinare le righe in
     `scriviRigheCopia`;
  4. lanciare `node test/controllo-copia.js` (deve dire «ok») e confrontare
     con le tabelle vere: `select table_name from information_schema.tables
     where table_schema='public'`;
  5. provare nel browser copia → cancellazione → ripristino.

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
- Controllo subappalti/subaffidamenti (livello `direzione` = capo cantiere/DT, non conteggiato): ditte sub con importo e lavorazioni
  comunicate (`ditte.importo_affidato`, `lavorazioni_affidate`); presenze nel
  giornale con livello, ore e lavorazione per riga (`maestranze` jsonb); costi
  orari contrattuali sul cantiere: `cantieri.costi_orari` jsonb {livello: €/h}
  per tutti i livelli di `LIVELLI_GRUPPI` (operai edili 4° liv./specializzato/
  qualificato/comune; operai metalmeccanici D1…C3, B1; impiegati D1…A1;
  `direzione` non conteggiato), con spiegazione breve per ciascuno (legenda
  `legendaLivelliHtml`, menu `opzioniLivelliHtml`). Nessun valore
  predefinito (cambiano ogni anno). Le colonne storiche `costo_ora_*`
  (comune/qualificato/specializzato/b1) restano allineate;
  `costoOrarioLivello(c, liv)` legge prima il jsonb. `ore_giornaliere`.
  `controlloSubappalti()` + `boxSubappaltiHtml()` (cantieri, dashboard, ditte,
  giornale): lavorazioni non comunicate e costo manodopera oltre l'importo.
  Report stampabile per ditta: `stampaReportSubappalto(dittaId)` (pulsante
  «🖨️ Report ore» in Ditte presenti). Contiene il **confronto per
  avanzamento**: `ditte.avanzamento_subappalto` jsonb `{sal_numero, data,
  righe:[{categoria, importo}]}` (lavori eseguiti dalla ditta al SAL, prezzi
  contrattuali; si inserisce nella scheda della ditta), `manodoperaAvanzamento
  (d,c)` = importo/(1−ribasso) × incidenza; ore registrate fino alla data del
  SAL a confronto. Se superano (oltre `SOGLIA_AVZ_MOLTO` = 120%: «di molto»)
  il report contiene una **«Richiesta di chiarimenti»** all'impresa (testo da
  inviare, niente commenti interni) con SOLO due punti: a) costi della
  manodopera del subappalto o del contratto inferiori a quelli reali →
  motivazioni e nuova incidenza; b) lavorazioni non autorizzate → chiarire ed
  eventualmente nuova richiesta di subappalto. La «minore produttività per
  l'organizzazione aziendale» NON va nel report (scelta dell'utente: la ditta
  potrebbe attribuirla alla DL): le tre cause (produttività, costi bassi,
  lavorazioni non autorizzate) con i riscontri compaiono solo DENTRO il
  gestionale, come avviso «nota interna» in `controlloSubappalti` (r.avanzamento)
  e nella riga della ditta. Seguono gli «Elementi rilevati dalla DL» (lavorazioni non
  autorizzate, presenze senza lavorazione, manodopera dichiarata/calcolata).
  Presenze di ditte sub senza «lavorazione svolta» (campo nato il 26/11/2026):
  avviso + pulsante «🧩 Completa lavorazioni» (`completaLavorazioniMancanti`)
  che scrive una lavorazione autorizzata in tutte le presenze vuote.
- Subappalti: limiti concessi a contratto nella scheda del cantiere
  (`cantieri.subappalto_categorie` jsonb `[{categoria, descrizione, importo,
  perc}]`, perc 0 = non subappaltabile; `subappalto_limite_perc` = limite
  complessivo facoltativo; categoria scelta dal menu `CATEGORIE_SOA` OG/OS).
  Una ditta può avere più categorie: `ditte.subappalto_categorie` jsonb
  `[{categoria, importo}]` (menu filtrato sulle categorie del contratto),
  `importo_affidato` = somma, `categoria_subappalto` = elenco leggibile;
  `categorieDitta(d)` legge anche le ditte vecchie con una sola categoria.
  La manodopera registrata si ripartisce fra le categorie della ditta in
  proporzione agli importi. **Importi delle categorie LORDI** (computo di
  progetto/variante, senza oneri della sicurezza) + `inc_mano` (% incidenza
  della manodopera del progetto, obbligatoria) nel jsonb; nella stessa sezione
  «Categorie di lavori, subappalto e manodopera» ci sono istruzioni numerate e
  i campi ribasso e oneri della sicurezza (obbligatori se ci sono categorie,
  allineati con `${prefix}_ribasso`/`_oneri` via `syncCampoSub`); l'app calcola il netto col
  `ribasso_percentuale` del cantiere (`nettoCategoria`) e applica i limiti al
  netto (omogeneo con i subappalti, prezzi contrattuali). Coerenza:
  Σ lordi × (1−ribasso) + oneri vigenti = importo vigente (`importoVigente
  Cantiere`, `oneriVigentiCantiere`: ultima variante); se no, avviso. Il limite
  complessivo si calcola sull'importo vigente. Ditta: `manodopera_subappalto`
  e `oneri_sicurezza_subappalto` dichiarati (art. 119 c.12: senza ribasso).
  Sicurezza: la sicurezza INCLUSA nei prezzi resta nei lordi delle categorie ed
  è ribassata; solo gli oneri della sicurezza SPECIALI (stimati a parte, PSC)
  non sono ribassati (cantiere `oneri_sicurezza`). Ditta: `sicurezza_inclusa_
  subappalto` = sicurezza compresa nei prezzi (il caso normale, facoltativa,
  informativa, non entra nei calcoli); `oneri_sicurezza_subappalto` solo se si
  subappaltano lavori relativi agli oneri speciali (spunta nel modulo): si
  tolgono prima di riportare al lordo.
  `manodoperaMinimaDitta(d,c)` = Σ (importo categoria − quota oneri speciali) /
  (1−ribasso) × incidenza: se la dichiarata è inferiore o superiore → solo
  avviso GIALLO «da verificare con la manodopera indicata in appalto» (scelta
  dell'utente: non è grave, il DL verifica con l'appalto). Se la ditta NON
  dichiara la manodopera: avviso con pulsante «✍️ Compila manodopera …»
  (riquadro subappalti, `compilaManodoperaDaContratto`) e nel modulo ditta
  «Compila con la manodopera da contratto»: valore = manodopera calcolata con
  le incidenze della scheda cantiere, salvato con `ditte.manodopera_calcolata`
  = true (indicato in tabella e report; niente confronto dichiarata/calcolata;
  se il DL scrive a mano un valore torna «dichiarata»). Anche la manodopera registrata nel
  giornale si confronta con la dichiarata. I costi orari del cantiere non
  vanno ribassati. Verifica al
  salvataggio della ditta (`verificaLimiteSubAlSalvataggio`, «Salva
  comunque») e segnalazioni in `problemiLimitiSub` dentro
  `controlloSubappalti`: importi autorizzati e manodopera registrata nel
  giornale contro il limite. Contano solo le subappaltatrici.
- Ordini di servizio (`ods`, `ODS_TIPI`: generico, senza_aumento,
  rimando_variante, **manodopera**). Il modello `manodopera` (aumento della
  manodopera per recupero del ritardo, art. 122 c.4) nasce dal pulsante del
  riquadro ritardi (`emettiOdsRitardo`): ritardi precompilati, giorni per
  adeguare la manodopera e per trasmettere il cronoprogramma aggiornato
  (default 10, minimo di legge), niente tavole né parte economica
  (`bodyOdsManodopera`). Per TUTTI gli ODS: sezione «Verifica
  dell'adempimento» (`dati_ods.verifica = {verbale, data}`, data proposta =
  data ODS + termine) → frase «verifica con verbale di sopralluogo» nel
  documento (`odsFraseVerifica`) e promemoria nel giornale dei lavori alla data
  della verifica (`odsPromemoriaVerifica` via `annotaGiornale`; in modifica
  solo se la data cambia). ODS generico: `dati_ods.giorni_termine` facoltativo.
  **Tutti gli ODS si inviano via PEC firmati digitalmente**: niente riquadri
  per la firma a mano (`apriDocumentoFirmabile` con `firmaDigitale: true` →
  solo ruolo e nome dei firmatari + dicitura di firma digitale, pulsante
  «Genera PDF (da firmare digitalmente)»; lo stesso in `stampaODS`). I
  verbali restano con la firma a mano.
- Conteggio giorni contrattuali: sospensioni, riprese, proroghe (una proroga
  non sospende i lavori).

### Copia di sicurezza (menu Sistema → 💾 Copia di sicurezza, solo DL)
- Scarica `gestione-cantieri-copia-AAAA-MM-GG.json` con tutte le tabelle dei
  cantieri di cui l'utente è DL (+ profili, solo consultazione). «!» rosso e
  promemoria in dashboard se l'ultima copia ha più di 7 giorni (data salvata
  nel browser, `localStorage` `gc_ultima_copia`).
- Ripristino: confronta file e dati di adesso (mancano / modificate / nuove),
  poi «solo quello che manca» oppure «anche le modifiche». Non cancella mai
  niente; prima scarica `…-prima-del-ripristino.json`. Rimette anche un
  cantiere eliminato per intero. Conferme disegnate nella finestra (niente
  `confirm`).
- Le righe le scrive `public.ripristina_righe(tabella, righe, sovrascrivi)`
  (`sql/2026-11-26-copia-sicurezza-ripristino.sql`): controlla che chi
  ripristina sia DL del cantiere, spegne i trigger di registro durante
  l'inserimento, sovrascrive solo righe di cantieri di cui si è DL.

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
  `crea_cantiere`, `ripristina_righe` (ripristino da copia), trigger di log su
  giornale/ods/sal.
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
