# Usare il gestionale con un altro account Claude (Team)

Il codice del gestionale **non sta nell'account Claude**: sta su GitHub
(`studioscs/gestione_cantieri`) e il database su Supabase. Un altro account
Claude deve solo **collegarsi** a questi due servizi. Le conversazioni fatte
con il vecchio account non si trasferiscono: tutto quello che serve per
continuare il lavoro è scritto nel file **`CLAUDE.md`** del repository, che
Claude legge da solo all'inizio di ogni sessione.

L'app pubblicata (https://studioscs.github.io/gestione_cantieri/) e gli utenti
che vi accedono non cambiano: non c'è niente da migrare.

---

## 1. GitHub — dare accesso al repository

Il nuovo account Claude lavora sul repository tramite un **utente GitHub**.

**a) Se il nuovo account userà lo stesso utente GitHub di oggi**
passa direttamente al punto 2.

**b) Se userà un altro utente GitHub**
1. Con l'utente GitHub proprietario di `studioscs`, apri
   https://github.com/studioscs/gestione_cantieri/settings/access
2. **Add people** → inserisci il nuovo utente GitHub → ruolo **Write**
   (o *Maintain*) → conferma.
3. Il nuovo utente accetta l'invito dalla mail di GitHub.

## 2. Claude — collegare GitHub al nuovo account

1. Accedi a **claude.ai** con il nuovo account Team.
2. Apri **https://claude.ai/connect-github** e collega l'utente GitHub del
   punto 1.
3. Nella stessa pagina installa la **Claude GitHub App** sul repository
   `studioscs/gestione_cantieri` (scegli *Only select repositories* →
   `gestione_cantieri`). Se il repository appartiene a un'organizzazione
   GitHub, l'installazione la deve fare (o approvare) un proprietario
   dell'organizzazione.
4. Se l'account Team è gestito da un amministratore e Claude Code o
   l'integrazione GitHub non compaiono, chiedi all'amministratore di
   abilitarli nelle impostazioni dell'organizzazione Claude.

## 3. Supabase — collegare il database

Il progetto usato dall'app è **SCS - gestionale cantiere DL**
(ref `kdshrvsaecdbcfpsoggz`).

1. **Accesso al progetto Supabase.** Se il nuovo account userà un'altra email
   Supabase: dal pannello Supabase, con l'account proprietario,
   *Organization settings → Team → Invite* e invita la nuova email con ruolo
   **Developer** o **Owner**. Accetta l'invito.
2. **Connettore in Claude.** Con il nuovo account apri
   **https://claude.ai/customize/connectors**, aggiungi il connettore
   **Supabase** e accedi con l'account Supabase che vede il progetto.
   Nei piani Team il connettore può doverlo aggiungere l'amministratore
   dell'organizzazione.
3. Senza connettore si lavora lo stesso: Claude darà il testo SQL da
   incollare nel *SQL Editor* di Supabase.

## 4. Aprire la prima sessione

1. Vai su **https://claude.ai/code** e avvia una nuova sessione scegliendo il
   repository **`studioscs/gestione_cantieri`** (i repository e i connettori
   si scelgono all'avvio: se li colleghi dopo, apri una sessione nuova).
2. Primo messaggio consigliato:

   > Leggi CLAUDE.md e docs/PROCEDURA_NUOVO_ACCOUNT.md. Verifica di poter
   > leggere il repository, fare push su un branch e accedere al progetto
   > Supabase `kdshrvsaecdbcfpsoggz` in sola lettura. Poi dimmi se è tutto
   > collegato.

3. Da lì si continua come sempre: richiesta → Claude modifica, fa la PR e il
   merge su `main` → GitHub Pages pubblica in pochi minuti → ricaricare la
   pagina e controllare la versione in basso.

## 5. Controllo finale

- [ ] Il nuovo utente GitHub vede e può modificare `studioscs/gestione_cantieri`
- [ ] Claude GitHub App installata sul repository
- [ ] Connettore Supabase attivo e il progetto `kdshrvsaecdbcfpsoggz` visibile
- [ ] In una sessione Claude Code il file `CLAUDE.md` viene letto (Claude
      risponde in italiano e conosce il flusso PR → merge su `main`)

## Cosa NON serve fare

- Copiare il codice: è già tutto su GitHub.
- Spostare il database o ricreare utenti dell'app.
- Riapplicare le migrazioni in `sql/`: sono già applicate sul database.
- Scollegare il vecchio account: i due account possono lavorare insieme
  (meglio non contemporaneamente sullo stesso branch).
