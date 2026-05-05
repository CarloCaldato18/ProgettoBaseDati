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

SELECT o.artista, COUNT(*) AS num_esib INTO temp 
FROM ogg_esib AS e JOIN ogg_arte AS o ON e.ID_ogg = o.ID
GROUP BY o.artista;

SELECT artista, MAX(num_esib)
FROM temp 
GROUP BY artista;

--da sistemare 

#Coppie di oggetti d'arte che sono sempre stati esposti assieme
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
