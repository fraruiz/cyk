CREATE OR REPLACE FUNCTION cyk(input_string text) RETURNS boolean AS $$
DECLARE
    N int; -- Longitud del string tokenizado
    i int; -- Contador para el bucle de setear_matriz
    start_symbol text;
BEGIN
    -- 1. Limpiar tablas
    DELETE FROM matriz_cyk;
    TRUNCATE tokens_entrada; -- Usa TRUNCATE para resetear serial

    -- 2. Tokenizar y almacenar (Aquí se necesita la lógica específica de tokenización)
    -- EJEMPLO SIMPLE DE PSEUDO-TOKENIZACIÓN (DEBE ADAPTARSE AL JSON REAL)
    -- Asumamos que cada carácter relevante o palabra clave es un token para el ejemplo
    
    -- LÓGICA DE TOKENIZACIÓN AQUÍ:
    -- Esto es complejo para JSON y debe considerar cadenas, números, y delimitadores.
    -- Para este ejemplo, solo usaremos los tokens básicos de la gramática FNC.
    -- ASUME UNA FUNCIÓN 'json_tokenize' EXISTE O LO HACES EN PL/PGSQL DIRECTO.

    INSERT INTO tokens_entrada (token)
    SELECT unnest(regexp_split_to_array(regexp_replace(input_string, '([{}":,])', ' \1 '), '\s+'))
    WHERE unnest <> '' AND unnest IS NOT NULL; -- Tokenización muy burda, mejorar!

    -- 3. Obtener N y Símbolo Inicial
    SELECT count(*) INTO N FROM tokens_entrada;
    SELECT parte_izq INTO start_symbol FROM GLC_en_FNC WHERE start = TRUE LIMIT 1;

    IF N = 0 AND start_symbol = 'S_EMPTY' THEN -- Caso especial de string vacío {}
        RETURN TRUE; -- Depende si tu GLC FNC soporta un símbolo para el vacío
    ELSIF N = 0 THEN
        RETURN FALSE;
    END IF;

    -- 4. Llamar a setear_matriz para llenar la matriz
    FOR i IN 1..N LOOP
        PERFORM setear_matriz(i);
    END LOOP;

    -- 5. Verificar resultado (X1, N)
    RETURN EXISTS (
        SELECT 1
        FROM matriz_cyk
        WHERE i = 1 AND j = N
        AND x @> ARRAY[start_symbol] -- @> verifica si el array contiene el elemento
    );

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION setear_matriz(l int) RETURNS void AS $$
DECLARE
    N int; -- Longitud total
    i int; -- Fila inicial de la subcadena
    j int; -- Fila final de la subcadena
    k int; -- Punto de partición
    current_token text;
    var_array text[]; -- Arreglo de variables para Xij
BEGIN
    SELECT count(*) INTO N FROM tokens_entrada;

    -- Caso BASE: longitud l = 1 (Diagonal principal: Xii)
    IF l = 1 THEN
        FOR i IN 1..N LOOP
            -- Obtener el token wi
            SELECT token INTO current_token FROM tokens_entrada WHERE indice = i;
            
            -- Buscar producciones A -> wi (tipo_produccion = 1)
            SELECT array_agg(parte_izq) INTO var_array
            FROM GLC_en_FNC
            WHERE tipo_produccion = 1 AND parte_der1 = current_token;
            
            -- Insertar en matriz_cyk
            IF var_array IS NOT NULL THEN
                INSERT INTO matriz_cyk (i, j, x) VALUES (i, i, var_array);
            END IF;
        END LOOP;

    -- Caso RECURSIVO: longitud l > 1 (Resto de la matriz: X i, i+l-1)
    ELSE
        FOR i IN 1..(N - l + 1) LOOP
            j := i + l - 1; -- j = índice final
            var_array := '{}'; -- Inicializar el arreglo para Xij
            
            -- Bucle de partición: k va de i a j-1
            FOR k IN i..(j - 1) LOOP
                -- Buscar variables A tal que A -> BC, B en Xik, C en Xk+1,j
                
                -- Variables en Xik
                WITH X_ik AS (
                    SELECT x FROM matriz_cyk WHERE i = i AND j = k
                ),
                -- Variables en Xk+1,j
                X_k1j AS (
                    SELECT x FROM matriz_cyk WHERE i = k + 1 AND j = j
                )
                -- Buscar las producciones A -> BC
                SELECT array_agg(DISTINCT G.parte_izq) INTO var_array
                FROM GLC_en_FNC G, X_ik, X_k1j
                WHERE G.tipo_produccion = 2 -- Producción Var -> Var Var
                  AND G.parte_der1 = ANY(X_ik.x) -- B está en Xik
                  AND G.parte_der2 = ANY(X_k1j.x) -- C está en Xk+1,j
                  -- El uso de array_cat y unnest es más eficiente que el append.
                  -- Agregamos las nuevas variables encontradas a las existentes en var_array
                  AND G.parte_izq <> ALL(var_array)
                ;
                
                -- Acumular las nuevas variables
                IF FOUND THEN
                    var_array := array_cat(var_array, var_array);
                    -- Se necesita un paso para remover duplicados si hay
                    var_array := ARRAY(SELECT DISTINCT unnest(var_array) ORDER BY 1);
                END IF;
                
            END LOOP; -- Fin bucle k (partición)

            -- Insertar el resultado final de Xij en matriz_cyk
            IF array_length(var_array, 1) IS NOT NULL AND array_length(var_array, 1) > 0 THEN
                INSERT INTO matriz_cyk (i, j, x) VALUES (i, j, var_array);
            END IF;

        END LOOP; -- Fin bucle i (índice de inicio)
    END IF;

END;
$$ LANGUAGE plpgsql;