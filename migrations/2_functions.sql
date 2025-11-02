CREATE OR REPLACE FUNCTION get_row_cells(level int, size int) RETURNS jsonb[] LANGUAGE plpgsql AS $$
    DECLARE
        result jsonb[] := ARRAY[]::jsonb[];
        i int;
        j int;
    BEGIN
        FOR i IN 1..(size - level + 1) LOOP
            j := i + level - 1;
            result := array_append(result, jsonb_build_object('i', i, 'j', j));
        END LOOP;

        RETURN result;
    END;
$$;

CREATE OR REPLACE FUNCTION clear_matrix() RETURNS void LANGUAGE plpgsql AS $$
    DECLARE
    BEGIN
        DELETE FROM cyk_matrix;
    END;
$$;

CREATE OR REPLACE FUNCTION set_matrix(value int) RETURNS void LANGUAGE plpgsql AS $$
    DECLARE
        index int;
    BEGIN
        FOR index IN 1..value LOOP
            INSERT INTO CYK_MATRIX (I, J, X) VALUES (index, value, ARRAY[]::TEXT[]);
        END LOOP;
    END;
$$;


CREATE OR REPLACE FUNCTION prepare_matrix(string text) RETURNS void LANGUAGE plpgsql AS $$
    DECLARE
        range int;
        index int;
    BEGIN
        SELECT LENGTH(string) into range;

        FOR index IN 1..range LOOP
            PERFORM set_matrix(index);
        END LOOP;
    END;
$$;

CREATE OR REPLACE FUNCTION solve_first_row(string text) RETURNS void LANGUAGE plpgsql AS $$
    DECLARE
        chars text[];
        char text;
        terminal_variables text[];
        index int;
        size int;
    BEGIN
        SELECT LENGTH(string) INTO size;
        SELECT regexp_split_to_array(string, '') INTO chars;

        FOR index IN 1..size LOOP
            char := chars[index];

            -- Find all terminal variables that produce char 
            SELECT ARRAY(
                SELECT G.LEFT_SYMBOL 
                FROM GLC G 
                WHERE G.TYPE = 1 
                AND G.FIRST_RIGHT_SYMBOL = char
            ) INTO terminal_variables;

            -- Update  
            UPDATE CYK_MATRIX SET X = terminal_variables WHERE I = index AND J = index;
        END LOOP;
    END;
$$;

CREATE OR REPLACE FUNCTION get_combinations(cell int[]) RETURNS jsonb[] LANGUAGE plpgsql AS $$
    DECLARE
        i int;
        j int;
        k int;
        result jsonb[] := '{}';
        comb jsonb;
    BEGIN
        i := cell[1];
        j := cell[2];

        IF i >= j THEN
            RETURN result;
        END IF;

        FOR k IN i..(j - 1) LOOP
            comb := jsonb_build_object(
                'first_cell', jsonb_build_object('i', i, 'j', k),
                'second_cell', jsonb_build_object('i', k+1, 'j', j)
            );
            result := array_append(result, comb);
        END LOOP;

        RETURN result;
    END;
$$;


CREATE OR REPLACE FUNCTION get_production_combinations(first_cell int[], second_cell int[]) RETURNS jsonb[] LANGUAGE plpgsql AS $$
    DECLARE
        results jsonb[];
    BEGIN
        WITH FIRST_BASE AS (
            SELECT UNNEST(M.X) AS VAL
            FROM CYK_MATRIX M
            WHERE M.I = first_cell[1]
            AND M.J = first_cell[2]
            -- Valida que no tenga producciones vacias
            AND M.X IS NOT NULL
            AND array_length(M.X, 1) > 0
        ), SECOND_BASE AS (
            SELECT UNNEST(M.X) AS VAL
            FROM CYK_MATRIX M
            WHERE M.I = second_cell[1]
            AND M.J = second_cell[2]
            -- Valida que no tenga producciones vacias
            AND M.X IS NOT NULL
            AND array_length(M.X, 1) > 0
            
        )
        SELECT array_agg(
                jsonb_build_object(
                    'first_value', F.VAL,
                    'second_value', S.VAL
                )
            ) INTO results
        FROM FIRST_BASE F, SECOND_BASE S;

        RETURN results;
    END;
$$;


CREATE OR REPLACE FUNCTION solve_cell(cell int[]) RETURNS void LANGUAGE plpgsql AS $$
    DECLARE
        combinations jsonb[];
        combination jsonb;
        first_cell int[];
        second_cell int[];
        results jsonb[];
        result jsonb;
        production text;
        productions text[];
    BEGIN
        SELECT get_combinations(cell) INTO combinations;

        FOREACH combination IN ARRAY combinations LOOP
            SELECT ARRAY[
                (combination->'first_cell'->>'i')::int,
                (combination->'first_cell'->>'j')::int
            ] INTO first_cell;
            SELECT ARRAY[
                (combination->'second_cell'->>'i')::int,
                (combination->'second_cell'->>'j')::int
            ] INTO second_cell;

            SELECT get_production_combinations(first_cell, second_cell) INTO results;

            IF results IS NULL THEN
                CONTINUE;
            END IF;

            FOREACH result IN ARRAY results LOOP
                SELECT G.LEFT_SYMBOL 
                INTO production
                FROM GLC G 
                WHERE G.FIRST_RIGHT_SYMBOL = result->>'first_value'
                AND G.SECOND_RIGHT_SYMBOL = result->>'second_value';

                IF production IS NOT NULL THEN
                    SELECT X INTO productions
                    FROM CYK_MATRIX AS M
                    WHERE M.I = cell[1] AND M.J = cell[2];

                    IF production IS NULL THEN
                        CONTINUE;
                    END IF;
        
                    UPDATE CYK_MATRIX AS M
                    SET X = COALESCE(productions, ARRAY[]::text[]) || ARRAY[production]
                    WHERE M.I = cell[1] AND M.J = cell[2];
                END IF;
            END LOOP;
        END LOOP;
    END;
$$;


CREATE OR REPLACE FUNCTION solve_row(level int, size int) RETURNS void LANGUAGE plpgsql AS $$
    DECLARE
        cells jsonb[];
        cell jsonb;
        pair int[];
    BEGIN
        SELECT get_row_cells(level, size) INTO cells;

        FOREACH cell IN ARRAY cells LOOP
            SELECT ARRAY[(cell->>'i')::int, (cell->>'j')::int] INTO pair;
            PERFORM solve_cell(pair);
        END LOOP;
    END;
$$;

CREATE OR REPLACE FUNCTION solve_matrix(string text) RETURNS void LANGUAGE plpgsql AS $$
    DECLARE
        level int;
        size int;
    BEGIN
        SELECT LENGTH(string) INTO size;

        FOR level IN 1..size LOOP
            IF level = 1 THEN
                PERFORM solve_first_row(string);
            ELSIF level >= 2 THEN 
                PERFORM solve_row(level, size);
            END IF;
        END LOOP;
    END;
$$;

CREATE OR REPLACE FUNCTION evaluate_result(string text) RETURNS boolean LANGUAGE plpgsql AS $$
    DECLARE
        size int;
        result boolean;
        start_symbol text;
    BEGIN
        SELECT LENGTH(string) INTO size;

        SELECT G.LEFT_SYMBOL
        INTO start_symbol
        FROM GLC G
        WHERE G.START = TRUE;

        SELECT 1
        INTO result
        FROM CYK_MATRIX M
        WHERE M.I = 1 AND M.J = size
        AND start_symbol = ANY(M.X);

        IF result IS NOT NULL THEN
            RETURN result;
        ELSE
            RETURN FALSE;
        END IF;
    END;
$$;


CREATE OR REPLACE FUNCTION cyk(string text) RETURNS text LANGUAGE plpgsql AS $$
    DECLARE
        result boolean;
    BEGIN
        PERFORM clear_matrix();

        PERFORM prepare_matrix(string);
        
        PERFORM solve_matrix(string);

        SELECT evaluate_result(string) into result;
        
        RETURN result;
    END;
$$;