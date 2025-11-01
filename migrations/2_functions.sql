CREATE OR REPLACE FUNCTION cyk(string text)
RETURNS text
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN 'Its okey';
END;
$$;
