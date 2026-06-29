-- 1. Tutti gli artisti di cui abbiamo almeno due oggetti di antiquariato

SELECT o.artista
FROM ogg_arte AS o
	JOIN ogg_antiquariato AS a ON o.ID=a.ID
WHERE o.artista IS NOT NULL
GROUP BY o.artista
HAVING COUNT(*) >= 2;

-- 2. Coppie di artisti che hanno esibito assieme

SELECT DISTINCT o1.artista, o2.artista
FROM ogg_esib AS e1 
	JOIN ogg_esib AS e2 ON e1.nomeEsibizione = e2.nomeEsibizione 
	JOIN ogg_arte AS o1 ON e1.ID_ogg = o1.ID 
	JOIN ogg_arte AS o2 ON e2.ID_ogg = o2.ID
WHERE o1.ID <> o2.ID AND o1.artista < o2.artista;

-- 3. Artista che ha partecipato al numero massimo di esibizioni 

WITH temp AS (
	SELECT o.artista, COUNT(DISTINCT e.NomeEsibizione) AS num_esib
	FROM ogg_esib AS e 
		JOIN ogg_arte AS o ON e.ID_ogg = o.ID
	WHERE o.artista IS NOT NULL
	GROUP BY o.artista
)
SELECT artista, num_esib
FROM temp 
WHERE num_esib = (SELECT MAX(num_esib) FROM temp); 

-- 4. Coppie di oggetti d'arte che sono sempre stati esposti assieme

SELECT DISTINCT ogg1.id_ogg, ogg2.id_ogg
FROM ogg_esib AS ogg1 
	JOIN ogg_esib AS ogg2 ON ogg1.nomeEsibizione = ogg2.nomeEsibizione
WHERE ogg1.id_ogg < ogg2.id_ogg 
	AND NOT EXISTS (
		SELECT ogg3.nomeEsibizione
		FROM ogg_esib AS ogg3
		WHERE ogg3.id_ogg = ogg1.id_ogg
		EXCEPT
		SELECT ogg4.nomeEsibizione
		FROM ogg_esib AS ogg4
		WHERE ogg4.id_ogg = ogg2.id_ogg 
  	) AND NOT EXISTS (
		SELECT ogg5.nomeEsibizione
		FROM ogg_esib AS ogg5
		WHERE ogg5.id_ogg = ogg2.id_ogg
		EXCEPT
		SELECT ogg6.nomeEsibizione
		FROM ogg_esib AS ogg6
		WHERE ogg6.id_ogg = ogg1.id_ogg
  	);

-- 5. Trovare le esibizioni uniche ossia quelle che espongono almeno un oggetto d'arte che non si trova in nessun altra esposizione

SELECT DISTINCT nomeEsibizione
FROM ogg_esib
WHERE id_ogg IN (
    SELECT id_ogg
    FROM ogg_esib
    GROUP BY id_ogg
    HAVING COUNT(*) = 1
);

-- 6. Per ogni artista e il suo stile principale trovare la tipologia di ogg arte più frequentemente creata
-- 6.1 associa ad ogni oggetto il suo tipo

CREATE VIEW v_tipo_oggetto AS
	SELECT o.ID, o.Artista, o.Stile, 'PITTURA' AS Tipo
	FROM OGG_ARTE AS o
		JOIN PITTURA AS p ON o.ID = p.ID
	UNION ALL
	SELECT o.ID, o.Artista, o.Stile, 'SCULTURA' AS Tipo
	FROM OGG_ARTE AS o
		JOIN SCULTURA AS s ON o.ID = s.ID
	UNION ALL
	SELECT o.ID, o.Artista, o.Stile, 'ANTIQUARIATO' AS Tipo
	FROM OGG_ARTE AS o
		JOIN OGG_ANTIQUARIATO AS a ON o.ID = a.ID
	UNION ALL
	SELECT o.ID, o.Artista, o.Stile, 'ALTRO' AS Tipo
	FROM OGG_ARTE AS o
	JOIN ALTRO AS alt ON o.ID = alt.ID;

-- 6.2 frequenza di ogni tipo per artista e stile

CREATE VIEW v_frequenza_tipo AS
	SELECT a.Nome, a.StileP, vt.Tipo, COUNT(*) AS frequenza
	FROM ARTISTA AS a
		JOIN v_tipo_oggetto AS vt ON a.Nome = vt.Artista AND a.StileP = vt.Stile
	GROUP BY a.Nome, a.StileP, vt.Tipo;

-- 6.3 massimo per ogni artista e stile

CREATE VIEW v_max_tipo AS
	SELECT Nome, StileP, MAX(frequenza) AS max_freq
	FROM v_frequenza_tipo
	GROUP BY Nome, StileP;

SELECT vf.Nome, vf.StileP, vf.Tipo, vf.frequenza
FROM v_frequenza_tipo AS vf
	JOIN v_max_tipo AS vm ON vf.Nome = vm.Nome AND vf.StileP = vm.StileP
WHERE vf.frequenza = vm.max_freq
ORDER BY vf.Nome;

-- OPPURE:

WITH TipoOggetto AS (
    SELECT o.ID, o.Artista, o.Stile, 'PITTURA' AS Tipo 
    FROM ogg_arte AS o
		JOIN pittura AS p ON o.ID = p.ID
	UNION ALL
    SELECT o.ID, o.Artista, o.Stile, 'SCULTURA' 
    FROM ogg_arte AS o
		JOIN scultura AS s ON o.ID = s.ID
    UNION ALL
    SELECT o.ID, o.Artista, o.Stile, 'ANTIQUARIATO' 
    FROM ogg_arte AS o
		JOIN ogg_antiquariato AS a ON o.ID = a.ID
    UNION ALL
    SELECT o.ID, o.Artista, o.Stile, 'ALTRO' 
    FROM ogg_arte AS o
		JOIN altro AS alt ON o.ID = alt.ID
), FrequenzaTipo AS (
    SELECT a.Nome, a.StileP, vt.Tipo, COUNT(*) AS frequenza
    FROM artista AS a
    	JOIN TipoOggetto AS vt ON a.Nome = vt.Artista 
    WHERE a.StileP = vt.Stile 
    GROUP BY a.Nome, a.StileP, vt.Tipo
)
SELECT f1.Nome, f1.StileP, f1.Tipo, f1.frequenza
FROM FrequenzaTipo AS f1
WHERE f1.frequenza = (
    SELECT MAX(f2.frequenza)
    FROM FrequenzaTipo AS f2
    WHERE f1.Nome = f2.Nome AND f1.StileP = f2.StileP
)
ORDER BY f1.Nome;	