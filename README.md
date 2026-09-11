# 🏛️ Progetto Basi di Dati — Museo d'Arte

Progetto per il corso di **Basi di Dati**: progettazione e implementazione di un database relazionale per la gestione delle collezioni di un museo d'arte, delle sue opere, degli artisti e delle esibizioni.

Il progetto copre l'intero ciclo di progettazione — concettuale, logica e fisica — con schema ER, script DDL, vincoli implementati tramite trigger, popolamento dei dati e query interpretative in PostgreSQL.

## 📑 Indice

- [Descrizione](#-descrizione)
- [Struttura del repository](#-struttura-del-repository)
- [Modello concettuale (ER)](#-modello-concettuale-er)
- [Modello logico](#-modello-logico)
- [Vincoli e trigger](#-vincoli-e-trigger)
- [Query](#-query)
- [Come eseguire il progetto](#-come-eseguire-il-progetto)
- [Documentazione](#-documentazione)

## 📖 Descrizione

Il database modella la gestione di un museo d'arte: gli **oggetti d'arte** (dipinti, sculture, oggetti d'antiquariato e altro) esposti o conservati, gli **artisti** che li hanno realizzati, gli **stili** artistici, le **esibizioni** temporanee in cui gli oggetti vengono mostrati, e lo stato di possesso di ciascun'opera (**in prestito** da un'altra collezione oppure parte della **collezione permanente** del museo).

Il modello concettuale presenta due gerarchie di specializzazione:

- **Stato di possesso** (totale e disgiunta): `Prestito` / `Permanente`
- **Tipologia dell'oggetto d'arte** (totale e disgiunta): `Pittura` / `Scultura` / `Oggetto d'antiquariato` / `Altro`

## 📂 Struttura del repository

```
ProgettoBaseDati/
├── src/
│   ├── DDL_Progetto.sql       # Definizione dello schema: tipi ENUM, tabelle, vincoli
│   ├── trigger.sql            # Trigger PL/pgSQL per i vincoli non esprimibili in DDL
│   ├── commenti.sql           # Note e motivazioni di progettazione su trigger e query
│   ├── queryProgetto.sql      # Query interpretative richieste dal progetto
│   ├── insert.sql             # Script di popolamento del database
│   ├── script_unico.sql       # Script completo (DDL + trigger + insert) pronto all'esecuzione
│   ├── ExInserts              # Esempi di inserimento di un oggetto d'arte "completo"
│   └── Insert/                # Script di insert suddivisi per singola tabella
│       ├── InsertArtista.sql
│       ├── InsertEsibizione.sql
│       ├── InsertStile.sql
│       ├── Insert_ogg_arte.sql
│       ├── InsertPittura.sql
│       ├── insertScultura.sql
│       ├── InsertOggAntiquariato.sql
│       ├── insertAltro.sql
│       ├── InsertPrestito.sql
│       ├── InsertPermanente.sql
│       ├── insertOggEsib.sql
│       └── liste.txt
└── doc/
    ├── Relazione Progetto Basi di Dati - Museo d'Arte.pdf   # Relazione completa del progetto
    ├── Relazione Progetto Basi di Dati - Museo d'Arte.docx
    ├── progettazione/
    │   ├── schemaER.jpeg               # Schema Entità-Relazione iniziale
    │   ├── SchemaER_ristrutturato.jpeg # Schema ER dopo la fase di ristrutturazione
    │   └── schemaLogico.jpeg           # Schema logico relazionale
    ├── testiQuery/
    │   └── proposteQuery.jpeg          # Testo delle query proposte dalla consegna
    └── consegna/
        ├── Consegna.pdf
        └── ConsegnaProgettoAppuntata.pdf
```

## 🗺️ Modello concettuale (ER)

Lo schema Entità-Relazione modella le seguenti entità principali:

| Entità | Descrizione |
|---|---|
| `Oggetto d'arte` | Entità padre di ogni opera del museo (titolo, anno, nazione, descrizione) |
| `Artista` | Autore delle opere (nome, date di nascita/morte, nazione, epoca, stile principale) |
| `Stile` | Corrente artistica associabile sia all'artista sia al singolo oggetto |
| `Esibizione` | Mostra temporanea a cui possono partecipare più oggetti d'arte |
| `Prestito` / `Permanente` | Specializzazione totale e disgiunta di `Oggetto d'arte` in base allo stato di possesso |
| `Pittura` / `Scultura` / `Oggetto d'antiquariato` / `Altro` | Specializzazione totale e disgiunta di `Oggetto d'arte` in base alla tipologia |

Schemi disponibili in `doc/progettazione/`:

- **`schemaER.jpeg`** — schema concettuale iniziale
- **`SchemaER_ristrutturato.jpeg`** — schema dopo la ristrutturazione (eliminazione delle gerarchie non necessarie, analisi delle ridondanze)
- **`schemaLogico.jpeg`** — traduzione nello schema logico relazionale

## 🧱 Modello logico

Lo schema è stato tradotto in **PostgreSQL**, con l'uso di tipi `ENUM` per i domini chiusi:

- `stato_opera`: `in prestito`, `in mostra`, `in magazzino`
- `tipo_pittura`: `olio su tela`, `acquerello`, `affresco`, `tempera`, `altro`
- `tipo_materiale_supporto`: `carta`, `legno`, `tela`, `altro`
- `materiale_scultura`: `marmo`, `bronzo`, `legno`, `altro`
- `tipo_epoca`: `antico`, `medievale`, `rinascimentale`, `barocco`, `moderno`, `contemporaneo`
- `tipo_altro`: `stampa`, `fotografia`, `manoscritto`, `altro`

**Tabelle principali** (`src/DDL_Progetto.sql`):

- `stile`, `artista`, `esibizione`, `ogg_arte`
- `prestito`, `permanente` (specializzazione per stato di possesso)
- `pittura`, `scultura`, `ogg_antiquariato`, `altro` (specializzazione per tipologia)
- `ogg_esib` (associazione N:M tra oggetti d'arte ed esibizioni)

Le gerarchie sono implementate con la tecnica **entità padre + entità figlie**, collegate da chiavi primarie che sono anche chiavi esterne verso `ogg_arte`, con `ON DELETE CASCADE`.

## 🔒 Vincoli e trigger

Oltre ai vincoli dichiarativi (`CHECK`, `PRIMARY KEY`, `FOREIGN KEY`), diversi vincoli di integrità — non esprimibili direttamente in DDL — sono implementati in `src/trigger.sql` tramite funzioni `PL/pgSQL`, in gran parte come `CONSTRAINT TRIGGER ... DEFERRABLE INITIALLY DEFERRED` per essere valutati al `COMMIT` (necessario per gestire le dipendenze circolari tra tabelle):

1. **Totalità artista → opere**: ogni artista inserito deve avere almeno un'opera in `ogg_arte`.
2. **Cardinalità minima opera → artista**: non è possibile eliminare o riassegnare l'ultima opera rimasta di un artista.
3. **Cardinalità minima oggetto → esibizione**: non è possibile rimuovere da una mostra ancora in corso l'ultimo oggetto esposto.
4. **Totalità e disgiunzione** tra `Prestito` e `Permanente`: ogni oggetto d'arte esistente deve comparire in una, e una sola, delle due tabelle.
5. **Totalità e disgiunzione** tra `Pittura`, `Scultura`, `Oggetto d'antiquariato` e `Altro`: ogni oggetto d'arte deve appartenere a esattamente una sottoclasse.

Le motivazioni di progettazione dietro ogni trigger sono documentate in `src/commenti.sql`.

## 🔍 Query

Le query interpretative richieste dalla consegna del progetto (`src/queryProgetto.sql`, testo in `doc/testiQuery/proposteQuery.jpeg`) includono, tra le altre:

1. Artisti con almeno due oggetti di antiquariato
2. Coppie di artisti che hanno esposto insieme in almeno una mostra
3. Artista/i che ha/hanno partecipato al maggior numero di esibizioni
4. Coppie di oggetti d'arte sempre esposti insieme (stesse esibizioni)
5. Esibizioni "uniche", cioè che espongono almeno un oggetto non presente in nessun'altra mostra
6. Per ogni artista, la tipologia di opera più frequente realizzata nel proprio stile principale (con due soluzioni alternative: tramite viste e tramite CTE)

## ⚙️ Come eseguire il progetto

Il progetto è pensato per **PostgreSQL**.

**Opzione 1 — Script unico** (consigliata):

```bash
psql -U <utente> -d <database> -f src/script_unico.sql
```

Esegue in sequenza DDL, trigger e popolamento dati.

**Opzione 2 — Passo per passo**:

```bash
# 1. Creazione dello schema (tipi, tabelle, vincoli)
psql -U <utente> -d <database> -f src/DDL_Progetto.sql

# 2. Creazione dei trigger e delle funzioni di vincolo
psql -U <utente> -d <database> -f src/trigger.sql

# 3. Popolamento del database
psql -U <utente> -d <database> -f src/insert.sql

# 4. Esecuzione delle query
psql -U <utente> -d <database> -f src/queryProgetto.sql
```

In alternativa agli insert aggregati in `src/insert.sql`, è possibile popolare le tabelle singolarmente eseguendo gli script in `src/Insert/` nell'ordine che rispetta le dipendenze (es. `Stile` e `Artista` prima di `Ogg_arte`, quest'ultimo prima delle sue specializzazioni).

## 📄 Documentazione

La relazione completa del progetto — con analisi dei requisiti, progettazione concettuale, ristrutturazione dello schema ER, progettazione logica e discussione delle scelte implementative — è disponibile in `doc/`:

- [`Relazione Progetto Basi di Dati - Museo d'Arte.pdf`](doc/Relazione%20Progetto%20Basi%20di%20Dati%20-%20Museo%20d'Arte.pdf)
- [`Relazione Progetto Basi di Dati - Museo d'Arte.docx`](doc/Relazione%20Progetto%20Basi%20di%20Dati%20-%20Museo%20d'Arte.docx)

Il testo originale della consegna del progetto è disponibile in `doc/consegna/`.

---

## 👤 Autore

Progetto realizzato per il corso di **Basi di Dati**.
