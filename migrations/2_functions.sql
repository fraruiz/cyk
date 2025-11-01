CREATE OR REPLACE FUNCTION cyk(string text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN 'Its okey';
END;
$$;


CREATE OR REPLACE FUNCTION set_matrix(val int)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    i smallint;
BEGIN
    -- Insert (val, val, [])
    INSERT INTO CYK_MATRIX (I, J, X) VALUES (val, val, '[]');
    
    -- Insert (val, i, []) for all i from 1 to val-1
    IF val > 1 THEN
        FOR i IN 1..(val - 1) LOOP
            INSERT INTO CYK_MATRIX (I, J, X) VALUES (val, i, '[]');
        END LOOP;
    END IF;
    
    -- Insert (i, val, []) for all i from 1 to val-1
    IF val > 1 THEN
        FOR i IN 1..(val - 1) LOOP
            INSERT INTO CYK_MATRIX (I, J, X) VALUES (i, val, '[]');
        END LOOP;
    END IF;
END;
$$;