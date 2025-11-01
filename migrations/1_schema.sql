CREATE TABLE GLC_en_FNC (
    start boolean,
    parte_izq text,
    parte_der1 text,
    parte_der2 text,
    tipo_produccion smallint -- 1 para Var -> terminal, 2 para Var -> Var1 Var2
);

CREATE TABLE matriz_cyk (
    i smallint,
    j smallint,
    x text[] -- Arreglo de texto para representar el conjunto de variables Xij
);

CREATE TEMP TABLE IF NOT EXISTS tokens_entrada (
    indice serial PRIMARY KEY,
    token text
);