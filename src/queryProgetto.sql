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

SELECT artista, COUNT(*) AS num_esib
FROM ogg_esib AS e JOIN ogg_arte AS o ON e.ID_ogg = o.ID
GROUP BY o.artista
WHERE MAX(num_esib); 
--da sistemare 

