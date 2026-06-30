-- 1. Quando viene aggiunto un artista, controllare esista un oggetto d'arte a suo nome 

CREATE FUNCTION check_artista()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
    DECLARE
        num_opere integer;
    BEGIN
        SELECT COUNT(*) INTO num_opere
        FROM OGG_ARTE
        WHERE Artista = NEW.Nome;

        IF num_opere = 0 THEN
            RAISE EXCEPTION 'Non esiste opera associata ad artista %', NEW.Nome;
        END IF;
        RETURN NULL;
    END;
$$;

CREATE CONSTRAINT TRIGGER trigger_check_artista
AFTER INSERT ON ARTISTA
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_artista();

-- 2. Quando elimino ultimo oggetto d'arte di un artista o modifico l'artista di un oggetto d'arte, controllare che non fosse l'unico associato all'artista

CREATE FUNCTION check_ultimo_ogg()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
    DECLARE
        num_opere integer;
    BEGIN
        SELECT COUNT(*) INTO num_opere
        FROM OGG_ARTE
        WHERE Artista = OLD.Artista;
        
        IF num_opere = 1 THEN
            RAISE EXCEPTION 'Oggetto % è unico associato ad %', OLD.ID, OLD.Artista;
        END IF;
        RETURN OLD;
    END;
$$;

CREATE TRIGGER trigger_check_ultimo_ogg
BEFORE UPDATE OR DELETE ON OGG_ARTE
FOR EACH ROW
WHEN (OLD.Artista IS DISTINCT FROM NEW.Artista OR TG_OP = 'DELETE')
EXECUTE FUNCTION check_ultimo_ogg();

-- 3. Quando viene spostato un oggetto d'arte da un'esibizione ad un'altra controllare che non fosse l'unico associato all'esibizione 
-- Nota: controllo solo su mostre non ancora concluse

CREATE FUNCTION check_ogg_esib()
RETURNS TRIGGER LANGUAGE plpgsql AS $$ 
    DECLARE 
        num_ogg integer;
    BEGIN
        SELECT COUNT(*) INTO num_ogg
        FROM OGG_ESIB
            JOIN ESIBIZIONE ON OGG_ESIB.NomeEsibizione = ESIBIZIONE.Nome
        WHERE OGG_ESIB.NomeEsibizione = OLD.NomeEsibizione 
            AND (ESIBIZIONE.DataFine > CURRENT_DATE);
        
        IF num_ogg = 1 THEN
            RAISE EXCEPTION 'Oggetto % è unico associato a esibizione %', OLD.ID_ogg, OLD.NomeEsibizione; 
        END IF;

        RETURN OLD; 
    END;
$$;
        
CREATE TRIGGER trigger_check_ogg_esib
BEFORE DELETE ON OGG_ESIB -- Sostituito OGG_ARTE con OGG_ESIB
FOR EACH ROW
EXECUTE FUNCTION check_ogg_esib();

-- 4. Controlla totalità e disgiunzione tra prestito e permanente

CREATE FUNCTION check_gerarchia_stato()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    id_chk integer;
    cnt integer;
BEGIN
    IF TG_OP = 'DELETE' THEN
        id_chk := OLD.ID;
    ELSE 
        id_chk := NEW.ID;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM OGG_ARTE WHERE ID = id_chk) THEN
        RETURN NULL;
    END IF;

    SELECT (
        (SELECT COUNT(*) FROM PRESTITO WHERE ID = id_chk) +
        (SELECT COUNT(*) FROM PERMANENTE WHERE ID = id_chk)
    ) INTO cnt;

    IF cnt = 0 THEN
        RAISE EXCEPTION 'Violazione Totalità: % non è né prestito né permanente', id_chk;
    ELSIF cnt > 1 THEN
        RAISE EXCEPTION 'Violazione Disgiunzione: % è sia prestito che permanente', id_chk;
    END IF;

    RETURN NULL;
END; $$;

CREATE CONSTRAINT TRIGGER trg_stato_prestito
AFTER INSERT OR UPDATE OR DELETE ON PRESTITO
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_gerarchia_stato();

CREATE CONSTRAINT TRIGGER trg_stato_permanente
AFTER INSERT OR UPDATE OR DELETE ON PERMANENTE
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_gerarchia_stato();

CREATE CONSTRAINT TRIGGER trg_stato_ogg_arte
AFTER INSERT OR UPDATE ON OGG_ARTE
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_gerarchia_stato();

-- 5. Controlla totalità e disgiunzione tra pittura, scultura, antiquariato e altro

CREATE FUNCTION check_gerarchia_esclusiva()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
    DECLARE
        id_da_controllare integer;
        conteggio_totale integer;
    BEGIN
        IF TG_OP = 'DELETE' THEN
            id_da_controllare := OLD.ID;
        ELSE
            id_da_controllare := NEW.ID;
        END IF;

        SELECT (
            (SELECT COUNT(*) FROM PITTURA WHERE ID = id_da_controllare) +
            (SELECT COUNT(*) FROM SCULTURA WHERE ID = id_da_controllare) +
            (SELECT COUNT(*) FROM OGG_ANTIQUARIATO WHERE ID = id_da_controllare) +
            (SELECT COUNT(*) FROM ALTRO WHERE ID = id_da_controllare)
        ) INTO conteggio_totale;
        
        IF conteggio_totale = 0 THEN
            RAISE EXCEPTION 'Violazione Totalità: Ogg_Arte % non appartiene a nessuna sottoclasse.', id_da_controllare;
        ELSIF conteggio_totale > 1 THEN
            RAISE EXCEPTION 'Violazione Disgiunzione: Ogg_Arte % appartiene a % sottoclassi contemporaneamente.', id_da_controllare, conteggio_totale;
        END IF;

        RETURN NULL;
    END;
$$;

-- Trigger sul Padre (controlla che non venga creato un padre senza figli)
CREATE CONSTRAINT TRIGGER check_gerarchia_padre
AFTER INSERT OR UPDATE ON OGG_ARTE
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_gerarchia_esclusiva();

-- Trigger sui Figli (controllano che non ci siano doppi figli o che non vengano cancellati lasciando il padre orfano)
CREATE CONSTRAINT TRIGGER check_gerarchia_pittura
AFTER INSERT OR UPDATE OR DELETE ON PITTURA
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_gerarchia_esclusiva();

CREATE CONSTRAINT TRIGGER check_gerarchia_scultura
AFTER INSERT OR UPDATE OR DELETE ON SCULTURA
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_gerarchia_esclusiva();

CREATE CONSTRAINT TRIGGER check_gerarchia_antiquariato
AFTER INSERT OR UPDATE OR DELETE ON OGG_ANTIQUARIATO
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_gerarchia_esclusiva();

CREATE CONSTRAINT TRIGGER check_gerarchia_altro
AFTER INSERT OR UPDATE OR DELETE ON ALTRO
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION check_gerarchia_esclusiva();