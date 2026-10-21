# Gestione cantieri — note per Claude

- App in un unico file `index.html` (GitHub Pages da `main`). Ad ogni modifica
  aggiornare `APP_VERSIONE`. Testi e risposte in italiano.
- Flusso: commit sul branch di lavoro → PR → squash merge su `main`.

## Supabase
- Progetto usato dall'app: **SCS - gestionale cantiere DL**, ref `kdshrvsaecdbcfpsoggz`
  (l'altro progetto `scs-gestionale` non è collegato all'app).
- Migrazioni: salvare il file in `sql/AAAA-MM-GG-descrizione.sql` (idempotente)
  e applicarlo con il connettore Supabase (`apply_migration` sul progetto sopra).
  Se il connettore non è disponibile nella sessione, dare all'utente il testo da
  incollare nel SQL Editor.
- `cantiere_utenti.ruolo` è un enum: nelle policy confrontare `ruolo::text`.
- Non archiviare copie dei documenti/PDF su Supabase (spazio limitato).
