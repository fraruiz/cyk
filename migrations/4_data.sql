\set content `cat /docker-entrypoint-initdb.d/data/calculator.json`

INSERT INTO GLC (START, LEFT_SYMBOL, FIRST_RIGHT_SYMBOL, SECOND_RIGHT_SYMBOL, TYPE)
SELECT
    (elem->>'START')::boolean,
    elem->>'LEFT_SYMBOL',
    elem->>'FIRST_RIGHT_SYMBOL',
    elem->>'SECOND_RIGHT_SYMBOL',
    (elem->>'TYPE')::smallint
FROM jsonb_array_elements(:'content'::jsonb) AS elem;
