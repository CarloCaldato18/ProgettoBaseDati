#Tutti gli artisti di cui abbiamo almeno due oggetti di antiquariato
SELECT o.artista
FROM ogg_arte AS o JOIN ogg_antiquariato AS a ON o.ID=a.ID
GROUP BY o.artista
HAVING COUNT(*) >= 2


