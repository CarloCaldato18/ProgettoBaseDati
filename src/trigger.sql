-- 1) Quando viene aggiunto un artista, controllare esista un oggetto d'arte a suo nome 

CREATE FUNCTION check_artista()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
    DECLARE
        num_opere integer;
    BEGIN 
        SELECT COUNT(*) into num_opere
        FROM OGG_ARTE
        WHERE OGG_ARTE.Artista = NEW.Nome;
        IF num_opere = 0 THEN
            RAISE EXCEPTION 'Non esiste opera associata ad artista %', NEW.Nome;
        END IF;
        RETURN NEW;
    END;
$$;

CREATE TRIGGER trigger_check_artista
BEFORE INSERT ON ARTISTA FOR EACH ROW EXECUTE FUNCTION check_artista()
WHEN NEW.Nome IS NOT NULL; 

-- 2) Quando elimino ultimo oggetto d'arte di un artista

CREATE FUNCTION check_ultimo_ogg()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
    DECLARE
        num_opere integer;
    BEGIN
        SELECT COUNT(*) into num_opere
        FROM OGG_ARTE
        WHERE OGG_ARTE.Artista = OLD.Artista
        GROUP BY Artista;
        IF num_opere = 1 THEN
            RAISE EXCEPTION 'Oggetto % è unico associato ad %', OLD.ID, OLD.Artista;
        END IF;
        RETURN OLD;
    END;
$$;

CREATE TRIGGER trigger_check_ultimo_ogg
BEFORE DELETE ON OGG_ARTE FOR EACH ROW EXECUTE FUNCTION check_ultimo_ogg

-- 3) Quando viene spostato un oggetto d'arte da un'esibizione ad un'altra controllare che non fosse l'unico associato all'esibizione

CREATE FUNCTION check_ogg_esib()
RETURN TRIGGER LANGUAGE plpgsql AS $$
    BEGIN
        PERFORM *
        FROM OGG_ESIB JOIN ESIBIZIONE ON OGG_ESIB.NomeEsibizione = ESIBIZIONE.Nome
        WHERE OGG_ESIB.NomeEsibizione = OLD.NomeEsibizione AND ESIBIZIONE.DataFine > CURRENT_DATE OR ESIBIZIONE.DataFine IS NULL;
        GROUP BY NomeEsibizione
        HAVING COUNT(*) = 1;
        IF FOUND THEN
            RAISE EXCEPTION 'Oggetto % è unico associato a esibizione %', OLD.ID_ogg, OGG_ESIB.NomeEsibizione;
        END IF;
        RETURN NEW;
    END;
$$;
        
CREATE TRIGGER trigger_check_ogg_esib
BEFORE DELETE ON OGG_ARTE FOR EACH ROW EXECUTE FUNCTION check_ogg_esib();

-- 4) Totalità: Controllare che se elimino un oggetto da prestito, esista un oggetto in permanente con lo stesso ID (vale lo stesso per il caso opposto)

CREATE FUNCTION check_delete_prestito()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
    BEGIN
        PERFORM *
        FROM PERMANENTE
        WHERE PERMANENTE.ID = OLD.ID;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Oggetto % è in prestito e non esiste un permanente con lo stesso ID', OLD.ID;
        END IF;
        RETURN OLD;
    END;
$$;

CREATE TRIGGER trigger_check_delete_prestito
BEFORE DELETE ON PRESTITO FOR EACH ROW EXECUTE FUNCTION check_delete_prestito();

-- 5) Disgiunzione: Controllare che prima di un inserimento l'oggetto non appartenga già ad un altro tipo.

CREATE FUNCTION check_tipo()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
    BEGIN
        PERFORM *
        FROM PITTURA JOIN SCULTURA ON PITTURA.ID = SCULTURA.ID JOIN OGG_ANTIQUARIATO ON PITTURA.ID = OGG_ANTIQUARIATO.ID 
        JOIN ALTRO ON PITTURA.ID = ALTRO.ID
        WHERE PITTURA.ID = NEW.ID;
        IF FOUNT THEN
            RAISE EXCEPTION 'Oggetto % appartiene a più di un tipo', NEW.ID;
        END IF;
        RETURN NEW;
    END;
$$;

CREATE TRIGGER trigger_check_tipo
BEFORE INSERT ON OGG_ARTE FOR EACH ROW EXECUTE FUNCTION check_tipo();
WHEN NEW.ID IS NOT NULL;
