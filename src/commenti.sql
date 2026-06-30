-- TRIGGER.sql

-- 1. Vincolo di totalità: ogni artista deve avere almeno un'opera in OGG_ARTE.
-- Implementato come CONSTRAINT TRIGGER DEFERRABLE INITIALLY DEFERRED per evitare lo stallo
-- generato dalla dipendenza circolare con la FK ogg_arte.artista -> artista.nome:
-- la verifica avviene al COMMIT, quando sia l'artista che la sua prima opera sono già stati inseriti.

-- 2. Vincolo di cardinalità minima (1) tra Artista e le sue opere.
-- Impedisce di cancellare l'ultima opera di un artista o di riassegnarla (UPDATE del campo Artista)
-- lasciando l'artista privo di opere. La clausola WHEN limita l'esecuzione ai soli DELETE
-- e agli UPDATE che modificano effettivamente il campo Artista, evitando controlli superflui
-- (e potenzialmente bloccanti) su aggiornamenti di altri campi dell'opera.

-- 3. Vincolo di cardinalità minima (1) tra Esibizione e le opere esposte.
-- Impedisce di rimuovere da OGG_ESIB l'ultimo oggetto di una mostra ancora in corso
-- (DataFine > CURRENT_DATE). Le mostre già concluse non sono soggette al vincolo.

-- 4. Vincolo di totalità e disgiunzione tra PRESTITO e PERMANENTE (stato di possesso dell'opera).
-- Implementato con CONSTRAINT TRIGGER DEFERRABLE INITIALLY DEFERRED su entrambe le tabelle figlie
-- (e sul padre OGG_ARTE): al COMMIT si verifica che ogni oggetto d'arte ancora esistente compaia
-- in PRESTITO o in PERMANENTE, mai in entrambe e mai in nessuna delle due.

-- 5. Vincolo di totalità e disgiunzione tra PITTURA, SCULTURA, OGG_ANTIQUARIATO e ALTRO.
-- Funzione unica condivisa da un CONSTRAINT TRIGGER sul padre (OGG_ARTE, INSERT/UPDATE) e da
-- un CONSTRAINT TRIGGER su ciascuna tabella figlia (INSERT/UPDATE/DELETE), tutti DEFERRABLE
-- INITIALLY DEFERRED: al COMMIT ogni oggetto d'arte deve comparire in esattamente una sottoclasse.

-- QUERY.sql

-- 1. Tutti gli artisti di cui abbiamo almeno due oggetti di antiquariato
-- (il filtro IS NOT NULL esclude dal raggruppamento gli eventuali oggetti non ancora
-- attribuiti a un artista, evitando una riga spuria con artista = NULL)

-- 3. Artista che ha partecipato al numero massimo di esibizioni
-- (COUNT(DISTINCT NomeEsibizione) conta le mostre distinte, non le righe di OGG_ESIB:
-- un artista con più opere nella stessa mostra non viene così sovrastimato)

-- 6. Per ogni artista e il suo stile principale (StileP) trovare la tipologia di oggetto
-- d'arte più frequentemente creata. Il filtro a.StileP = vt.Stile è intenzionale: si contano
-- solo le opere realizzate nello stile principale dichiarato per l'artista, non tutte le sue opere.