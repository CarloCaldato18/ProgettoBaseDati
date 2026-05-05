# File di definizione del database per il progetto avente come tema un museo d'arte e le opere che contiene 

CREATE TYPE stato_opera AS ENUM ('in prestito', 'in mostra', 'in magazzino');
CREATE TYPE tipo_pittura AS ENUM ('olio su tela', 'acquerello', 'affresco', 'tempera', 'altro');
CREATE TYPE tipo_materiale_supporto AS ENUM ('carta', 'legno', 'tela', 'altro');
CREATE TYPE materiale_scultura AS ENUM ('marmo', 'bronzo', 'legno', 'altro');
CREATE TYPE tipo_epoca AS ENUM ('antico', 'medievale', 'rinascimentale', 'barocco', 'moderno', 'contemporaneo');
CREATE TYPE tipo_altro AS ENUM ('stampa', 'fotografia', 'manoscritto', 'altro');

-- CREATE DATABASE museo;
-- USE museo;

CREATE TABLE stile (
    nome VARCHAR(256) PRIMARY KEY
);

CREATE TABLE artista (
    nome VARCHAR(256) PRIMARY KEY,
    dataNascita DATE CHECK (dataNascita <= CURRENT_DATE),
    dataMorte DATE,
    nazione VARCHAR(256),
    epoca tipo_epoca,
    descrizione VARCHAR(1024),
    stileP VARCHAR(256) REFERENCES stile(nome),
    CHECK (dataMorte IS NULL OR dataMorte >= dataNascita)
);

CREATE TABLE esibizione (
    nome VARCHAR(256) PRIMARY KEY,
    dataInizio DATE NOT NULL,
    dataFine DATE NOT NULL,
    CHECK (dataFine >= dataInizio)
);

CREATE TABLE ogg_arte (
    ID SERIAL PRIMARY KEY,
    titolo VARCHAR(256) NOT NULL,
    anno INTEGER CHECK (anno <= EXTRACT(YEAR FROM CURRENT_DATE)),
    nazione VARCHAR(256) NOT NULL,
    descrizione VARCHAR(1024) NOT NULL,
    artista VARCHAR(256) REFERENCES artista(nome),
    stile VARCHAR(256) REFERENCES stile(nome)
);

CREATE TABLE prestito (
    ID INTEGER PRIMARY KEY REFERENCES ogg_arte(ID) ON DELETE CASCADE,
    collezioneProvenienza VARCHAR(256) NOT NULL,
    inizioPrestito DATE NOT NULL,
    finePrestito DATE NOT NULL,
    CHECK (finePrestito >= inizioPrestito)
);

CREATE TABLE permanente (
    ID INTEGER PRIMARY KEY REFERENCES ogg_arte(ID) ON DELETE CASCADE,
    dataAcquisizione DATE NOT NULL CHECK (dataAcquisizione <= CURRENT_DATE),
    costo DOUBLE PRECISION NOT NULL CHECK (costo >=0),
    stato stato_opera NOT NULL
);

CREATE TABLE pittura (
    ID INTEGER PRIMARY KEY REFERENCES ogg_arte(ID) ON DELETE CASCADE,
    tipo tipo_pittura NOT NULL,
    materialeSupporto tipo_materiale_supporto NOT NULL
);

CREATE TABLE scultura (
    ID INTEGER PRIMARY KEY REFERENCES ogg_arte(ID) ON DELETE CASCADE,
    materiale materiale_scultura NOT NULL,
    altezza DOUBLE PRECISION NOT NULL,
    larghezza DOUBLE PRECISION NOT NULL,
    statua BOOLEAN NOT NULL,
    CHECK (altezza > 0 AND larghezza > 0)
);

CREATE TABLE ogg_antiquariato (
    ID INTEGER PRIMARY KEY REFERENCES ogg_arte(ID) ON DELETE CASCADE,
    epoca tipo_epoca NOT NULL
);

CREATE TABLE altro (
    ID INTEGER PRIMARY KEY REFERENCES ogg_arte(ID) ON DELETE CASCADE,
    tipo tipo_altro NOT NULL
);

CREATE TABLE ogg_esib (
    nomeEsibizione VARCHAR(256) REFERENCES esibizione(nome),
    ID_ogg INTEGER REFERENCES ogg_arte(ID) ON DELETE CASCADE,
    PRIMARY KEY (nomeEsibizione, ID_ogg)
);