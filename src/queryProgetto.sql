-- Active: 1777990354116@@ep-holy-smoke-alb66fkq-pooler.c-3.eu-central-1.aws.neon.tech@5432@ProgettoMuseo
-- Tutti gli artisti di cui abbiamo almeno due oggetti di antiquariato

SELECT o.artista
FROM ogg_arte AS o JOIN ogg_antiquariato AS a ON o.ID=a.ID
GROUP BY o.artista
HAVING COUNT(*) >= 2;

  -- Coppie di artisti che hanno esibito assieme

SELECT DISTINCT o1.artista, o2.artista
FROM ogg_esib AS e1 JOIN ogg_esib AS e2 ON e1.nomeEsibizione = e2.nomeEsibizione JOIN
    ogg_arte AS o1 ON e1.ID_ogg = o1.ID JOIN ogg_arte AS o2 ON e2.ID_ogg = o2.ID
WHERE o1.ID <> o2.ID AND o1.artista <> o2.artista;

-- Artista che ha partecipato al numero massimo di esibizioni 

WITH temp (artista, num_esib) AS (
  SELECT o.artista, COUNT(e.NomeEsibizione) 
  FROM ogg_esib AS e JOIN ogg_arte AS o ON e.ID_ogg = o.ID
  GROUP BY o.artista)
SELECT artista, MAX(num_esib)
FROM temp 
GROUP BY artista;

--da sistemare 

-- Coppie di oggetti d'arte che sono sempre stati esposti assieme
SELECT ogg1.ID, ogg2.ID
FROM ogg_esib AS ogg1 JOIN ogg_esib AS ogg2 ON ogg1.nomeEsibizione = ogg2.nomeEsibizione
WHERE ogg1.ID < ogg2.ID AND NOT EXISTS (
    SELECT ogg3.nomeEsibizione
    FROM ogg_esib AS ogg3
    WHERE ogg3.ID=ogg1.ID
    EXCEPT
    SELECT ogg4.nomeEsibizione
    FROM ogg_esib AS ogg4
    WHERE ogg4.ID=ogg2.ID 
) AND NOT EXISTS (
    SELECT ogg5.nomeEsibizione
    FROM ogg_esib AS ogg5
    WHERE ogg5.ID=ogg2.ID
    EXCEPT
    SELECT ogg6.nomeEsibizione
    FROM ogg_esib AS ogg6
    WHERE ogg6.ID=ogg1.ID
)

-- Trovare le esibizioni uniche ossia quelle che espongono almeno un oggetto d'arte che non si trova in nessun altra esposizione
SELECT DISTINCT e.nome
FROM esibizione AS e
WHERE e.nome NOT IN (
	SELECT e1.nome
	FROM esibizione AS e1
	JOIN ogg_esib ON e1.nome=ogg_esib.nomeEsibizione
	GROUP BY ogg_esib.ID_ogg
	HAVING COUNT(ogg_esib.ID_ogg)>1
)


-- Per ogni artista e il suo stile trovare la tipologia di ogg arte più frequentemente creata

-- associa ad ogni oggetto il suo tipo
CREATE VIEW v_tipo_oggetto AS
SELECT o.ID, o.Artista, o.Stile, 'PITTURA' AS Tipo
FROM OGG_ARTE AS o JOIN PITTURA AS p ON o.ID = p.ID
UNION ALL
SELECT o.ID, o.Artista, o.Stile, 'SCULTURA' AS Tipo
FROM OGG_ARTE AS o JOIN SCULTURA AS s ON o.ID = s.ID
UNION ALL
SELECT o.ID, o.Artista, o.Stile, 'ANTIQUARIATO' AS Tipo
FROM OGG_ARTE AS o JOIN OGG_ANTIQUARIATO AS a ON o.ID = a.ID
UNION ALL
SELECT o.ID, o.Artista, o.Stile, 'ALTRO' AS Tipo
FROM OGG_ARTE AS o JOIN ALTRO AS alt ON o.ID = alt.ID;

-- frequenza di ogni tipo per artista e stile
CREATE VIEW v_frequenza_tipo AS
SELECT a.Nome, a.StileP, vt.Tipo, COUNT(*) AS frequenza
FROM ARTISTA AS a
JOIN v_tipo_oggetto AS vt ON a.Nome = vt.Artista AND a.StileP = vt.Stile
GROUP BY a.Nome, a.StileP, vt.Tipo;

-- massimo per ogni artista e stile
CREATE VIEW v_max_tipo AS
SELECT Nome, StileP, MAX(frequenza) AS max_freq
FROM v_frequenza_tipo
GROUP BY Nome, StileP;


SELECT vf.Nome, vf.StileP, vf.Tipo, vf.frequenza
FROM v_frequenza_tipo AS vf
JOIN v_max_tipo AS vm ON vf.Nome = vm.Nome AND vf.StileP = vm.StileP
WHERE vf.frequenza = vm.max_freq
ORDER BY vf.Nome;
