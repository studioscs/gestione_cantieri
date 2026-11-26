// Controllo: copia di sicurezza e ripristino coprono tutte le tabelle?
// Uso: node test/controllo-copia.js   (esce con errore se qualcosa non torna)
// 1) ogni tabella usata dall'app (sb.from('...')) deve stare in TABELLE_COPIA
// 2) ORDINE_RIPRISTINO (index.html) deve coincidere con l'elenco «consentite»
//    di ripristina_righe nell'ultima migrazione sql che la definisce.
// Ricordarsi anche di confrontare con le tabelle vere del database:
//   select table_name from information_schema.tables where table_schema='public';
const fs = require('fs'), path = require('path');
const root = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const lista = (src, nome) => {
  const m = src.match(new RegExp(nome + '\\s*(?:constant\\s+text\\[\\]\\s*)?(?::=\\s*array|=)\\s*\\[([^\\]]*)\\]'));
  if (!m) throw new Error('Elenco ' + nome + ' non trovato');
  return [...m[1].matchAll(/'([a-z_]+)'/g)].map(x => x[1]);
};
const ordine = lista(html, 'const ORDINE_RIPRISTINO');
const copia = new Set(ordine.concat(['profiles']));
const usate = new Set([...html.matchAll(/\.from\(\s*'([a-z_]+)'\s*\)/g)].map(m => m[1]));
const sqlDir = path.join(root, 'sql');
const fileSql = fs.readdirSync(sqlDir).filter(f => f.endsWith('.sql')).sort()
  .filter(f => /function\s+public\.ripristina_righe/.test(fs.readFileSync(path.join(sqlDir, f), 'utf8')));
const ultima = fileSql[fileSql.length - 1];
const consentite = lista(fs.readFileSync(path.join(sqlDir, ultima), 'utf8'), 'consentite');
const errori = [];
for (const t of usate) if (!copia.has(t)) errori.push(`la tabella "${t}" è usata dall'app ma non è in ORDINE_RIPRISTINO`);
for (const t of ordine) if (!consentite.includes(t)) errori.push(`"${t}" è in ORDINE_RIPRISTINO ma non in ripristina_righe (${ultima})`);
for (const t of consentite) if (!ordine.includes(t)) errori.push(`"${t}" è in ripristina_righe (${ultima}) ma non in ORDINE_RIPRISTINO`);
const nomi = lista(html.replace(/const NOMI_TABELLE_COPIA = \{([\s\S]*?)\};/, (_, b) => 'const NOMI_X = [' + [...b.matchAll(/([a-z_]+)\s*:/g)].map(m => `'${m[1]}'`).join(',') + ']'), 'const NOMI_X');
for (const t of copia) if (!nomi.includes(t)) errori.push(`"${t}" non ha un nome in NOMI_TABELLE_COPIA`);
if (errori.length) { console.error('COPIA/RIPRISTINO NON ALLINEATI:\n- ' + errori.join('\n- ')); process.exit(1); }
console.log(`ok: ${ordine.length} tabelle ripristinabili, allineate con ${ultima}; tabelle usate dall'app tutte coperte`);
