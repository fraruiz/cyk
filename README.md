# **Trabajo Práctico**
## Teoría de la computación

**Autores:**  
> - Arévalo, Sabrina
> - Sia, Giovanni
> - Ruiz Lezcano, Francisco

**Profesor/a:**  
> Ignacio Bisso

**Fecha de entrega:**  
> 11/11/2025
---

## 1. Introducción
El presente trabajo tiene como objetivo aplicar el **algoritmo CYK (Cocke–Younger–Kasami)** para reconocer cadenas válidas del lenguaje **JSON (JavaScript Object Notation)**. Para ello, se define una **Gramática Libre de Contexto (GLC)** que describe la estructura de JSON y se transforma a su **Forma Normal de Chomsky (FNC)**, requisito esencial para la ejecución del algoritmo. Mediante la implementación del CYK, se verifica si una cadena pertenece al lenguaje generado, integrando los conceptos de gramáticas, normalización y reconocimiento sintáctico.

**JSON** es un formato intercambio de datos. Para nuestro trabajo práctica, un JSON se compone de una estructura principal: objetos, que son colecciones no ordenadas de pares clave-valor delimitadas por llaves `{}` y separadas por comas. Un par clave-valor se escribe como una cadena de texto entre comillas para la clave, seguida de dos puntos y el valor, que puede ser una cadena, número, booleano, nulo u objeto.  

### 1.1 Estructura básica: Objeto
Un objeto comienza con `{` y termina con `}`. Contiene pares clave-valor, los pares se separan por comas. Luego, la clave es siempre una cadena de texto entre comillas dobles, seguida de dos puntos y el valor. Los tipos de datos para un valor son:
- **Cadenas de texto**: entre comillas dobles, como "nombre"
- **Números**: aceptaremos números enteros positivos o negativos. 
- **Boolean**: true o false. 
- **Nulo**: null
- **Objetos**: anidados dentro de otro objeto. 

## 2. Gramática libre de contexto
Sea G = ⟨T, V, P, S⟩, donde las terminales y producciones son:

```
T = {
    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 0, -
    true, false, null, {, }, ", :
}
```

```
P = {
    S       → {PAIRS} | {}
    PAIRS   → PAIR | PAIR, PAIRS
    PAIR    → KEY : VALUE
    KEY     → STRING
    VALUE   → NULL | BOOLEAN | INTEGER | STRING | S
    STRING  → "CHARS"
    CHARS   → CHAR | CHAR CHARS | ϵ
    INTEGER → NUMERIC | NUMERIC INTEGER
    NULL    → null
    BOOLEAN → true | false
    NUMERIC → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    CHAR    → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
              a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
              1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
}
```

## 3. Árbol de parsing

Sea w = `{"a":10,"b":"hola","c":{"d":"chau","e":99},"f":{}}`

<img width="6259" height="2782" alt="Arbol de Parsing" src="https://github.com/user-attachments/assets/22c0a882-4538-4568-9c93-0c9fe6518897" />


Sea w = `{"ca":{"e":99,"g":{"h":12}}}`

![Árbol de parsing](Arbol_parcing2.png)

## 4. Aplicación de algoritmos de limpieza
En el contexto de la formas normales de Chomsky, debemos aplicar, previo al proceso de normalización, los siguientes algoritmos de limpieza en orden:
1. Eliminar ϵ-producciones
2. Eliminar producciones unitarias
3. Eliminar símbolos no generadores
4. Eliminar símbolos no alcanzados

### 4.1. Eliminar ϵ-producciones
Para eliminar las producciones ϵ, necesitamos primero descubrir las variables nulleables; es decir, variables tales que A ⇒∗ ϵ. Por ello, sea G = ⟨T, V, P, S⟩ mencionado anteriormente:
- **Caso base:** Si existe `A → ϵ`, entonces A es nullable. Por ello, notemos que `CHARS` es nullable pues `CHARS → ϵ`
- **Caso inductivo:** Si existe `A → α` y `α ⇒∗ ϵ`, entonces A es nullable. Por ello, observemos que `STRING → CHARS` obteniendo una derivación iterada `STRING ⇒∗ ϵ`. Finalmente, STRING es un símbolo nullable.

Una vez identificadas los símbolos nullables, debemos identificar todos las producciones tal que de lado derecho contenga el símbolo nullable. Consecuentemente, generaremos todas las combinaciones de producciones posibles, obteniendo:

```
P' = {
    S       → {PAIRS} | {}
    PAIRS   → PAIR | PAIR, PAIRS
    PAIR    → KEY : VALUE
    KEY     → STRING
    VALUE   → NULL | BOOLEAN | INTEGER | STRING | S
    STRING  → "CHARS" | ""
    CHARS   → CHAR | CHAR CHARS
    INTEGER → NUMERIC | NUMERIC INTEGER
    NULL    → null
    BOOLEAN → true | false
    NUMERIC → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    CHAR    → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
              a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
              1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
}
```

### 4.2. Eliminar producciones unitarias
Consideremos una producción unitaria tal que su lado derecho consiste exactamente una varaible. Si `A ⇒∗ B` por una serie de producciones unitarias, y `B ⇒∗ α` es una producción unitaria, entonces agregar `A ⇒∗ α`. Luego eliminar todos las producciones unitaras. 

Por lo tanto, debemos decubrir todas producciones unitarias. Para ello, debemos encontrar todos los pares (A,B) tales que `A ⇒∗ B` por una secuencia de producciones unitarias. Llamamos (A,B) pares unitarios.
- **Caso base:** Para cada varible A, agregar (A,A). Por ello, obtenemos `(S,S), (PAIRS,PAIRS), (PAIR,PAIR), (VALUE,VALUE), (KEY,KEY), (STRING,STRING), (CHARS,CHARS), (INTEGER,INTEGER), (NULL,NULL), (BOOLEAN,BOOLEAN), (NUMERIC,NUMERIC), (CHAR,CHAR)`.
- **Caso inductivo:** Para cada `A → B` agregamos `(A,B)`. Por consiguiente,, si `B → C`, entonces agregar `(B,C)`. Por ello, obtenemos `(PAIRS,PAIR),(VALUE,NULL),(VALUE,BOOLEAN),(VALUE,INTEGER),(VALUE,NUMERIC),(VALUE,STRING),(VALUE,S),(KEY,STRING),(CHARS,CHAR),(INTEGER,NUMERIC)`.

Para cada par unitario, debemos agregar a `P''` todas las producciones `A ⇒∗ α`, dónde `B ⇒ α` es una producción no unitaria en P y `A ⇒ B`. Observemos que obtenemos:
1. `PAIRS ⇒* PAIR`
2. `KEY ⇒* STRING`
3. `VALUE ⇒* NULL`
4. `VALUE ⇒* BOOLEAN`
5. `VALUE ⇒* NUMERIC`
6. `VALUE ⇒* STRING`
7. `VALUE ⇒* S`
8. `CHARS ⇒* CHAR`
9. `INTEGER ⇒* NUMERIC`

Consecuentemente, las nuevas producciones son:
- `PAIRS  → KEY : VALUE`
- `STRING → "CHARS" | ""`
- `VALUE → null`
- `VALUE → true | false`
- `VALUE → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER`
- `VALUE → "CHARS" | ""`
- `VALUE → {PAIRS} | {}`
- `CHARS → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
           a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
           1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0`
- `INTEGER → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9`

Finalmente
```
P'' = {
    S       → {PAIRS} | {}
    PAIRS   → KEY : VALUE | PAIR, PAIRS
    PAIR    → KEY : VALUE
    KEY     → "CHARS" | ""
    VALUE   → null | true | false | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER | "CHARS" | "" | {PAIRS} | {}
    STRING  → "CHARS" | ""
    CHARS   → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
              a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
              1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | CHAR CHARS
    INTEGER → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER
    NULL    → null
    BOOLEAN → true | false
    NUMERIC → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    CHAR    → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
              a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
              1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
}
```

### 4.3. Eliminar símbolos no generadores
Consideremos a los símbolos generadores tales `A ⇒∗ w`, siendo w un string de terminales. Descubramos los símbolos generadores:
- **Caso base**: Agregar `a ∈ T` a RES, obteniendo: 
    ```
    RES = {
        A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
        a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
        1, 2, 3, 4, 5, 6, 7, 8, 9, 0, -
        true, false, null, {, }, ", : 
    }
    ```
- **Caso inductivo**: Si existe `A → α` en P y `α ∈ RES`, entonces agregar A en RES. Notemos que:
    - `S → {}`
    - `PAIRS   → KEY : VALUE`
    - `PAIR    → KEY : VALUE`
    - `KEY     → ""`
    - `VALUE   → null`
    - `STRING  → ""`
    - `CHARS   → A`
    - `INTEGER → 0`
    - `NULL    → null`
    - `BOOLEAN → true`
    - `NUMERIC → 0`
    - `CHAR    → A`
    Por ende, obtenemos:
    ```
    RES = {
        A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
        a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
        1, 2, 3, 4, 5, 6, 7, 8, 9, 0, -
        true, false, null, {, }, ",
        S,PAIRS,PAIR,KEY,VALUE,STRING,CHARS,INTEGER,NULL,BOOLEAN,NUMERIC,CHAR
    }
    ```

Finalmente obtenemos que no hay símbolos NO generadores, pues no hay variable de la GLC tal que no esté en RES. Por ello, no aplica eliminar símbolos no generadores.

### 4.4. Eliminar símbolos no alcanzados
Decimos que un símbolo X (terminal o no terminal) es alcanzable si `S ⇒∗ 𝛼𝑋𝛽`, para algun string 𝛼 y 𝛽 compuesto
de terminales y no terminales. Sea G = ⟨T, V, P'', S⟩:
- **Caso base:** Podemos alcanzar S (el símbolo inicial)
- **Caso inductivo:** Si podemos alcanzar A, y existe una producción `A → α`, entonces podemos alcanzar todos los
símbolos de α.

Observemos que símbolos alcanzables son `RES = {S,PAIRS,PAIR,KEY,VALUE,CHARS,INTEGER,NUMERIC,CHAR}`. Consecuentemente, los símbolos no alcanzables son `RESᶜ = {NULL,STRING,BOOLEAN}`

```
P''' = {
    S       → {PAIRS} | {}
    PAIRS   → KEY : VALUE | PAIR, PAIRS
    PAIR    → KEY : VALUE
    KEY     → "CHARS" | ""
    VALUE   → null | true | false | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER | "CHARS" | "" | {PAIRS} | {}
    CHARS   → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
              a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
              1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | CHAR CHARS
    INTEGER → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER
    NUMERIC → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    CHAR    → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
              a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
              1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
}
```

## 5. Forma normal de Chomsky
Sea G = ⟨T, V, P, S⟩, donde las terminales y producciones son:

```
T = {
    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 0, -
    true, false, null, {, }, ", :
}
```
```
P = {
    S       → {PAIRS} | {}
    PAIRS   → KEY : VALUE | PAIR, PAIRS
    PAIR    → KEY : VALUE
    KEY     → "CHARS" | ""
    VALUE   → null | true | false | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER | "CHARS" | "" | {PAIRS} | {}
    CHARS   → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
              a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
              1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | CHAR CHARS
    INTEGER → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER
    NUMERIC → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    CHAR    → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
              a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
              1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
}
```

Una GLC está en FNC si cada producción cumple con alguna de las dos condiciones:
- El lado derecho son dos variables (por ej: `A → BC`)
- El lado derecho es una terminal (por ej: `A → a`)

Observemos que producciones que no cumplen las condiciones son:
- `S → {PAIRS}`
- `S → {}`
- `PAIRS → KEY : VALUE`
- `PAIRS → PAIR, PAIRS`
- `PAIR  → KEY : VALUE`
- `KEY → "CHARS"`
- `KEY → ""`
- `VALUE → "CHARS"`
- `VALUE → ""`
- `VALUE → {PAIRS}`
- `VALUE → {}`

Como primer paso, debemos limpiar la gramática para que cada lado derecho de las producciones sea un terminal o tenga longitud al menos dos. Por ello, las nuevas producciones son:
```
P' = {
    S                   → LEFT_CURLY_BRACKET PAIRS RIGHT_CURLY_BRACKET | LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
    PAIRS               → KEY COLON VALUE | PAIR COMMA PAIRS
    PAIR                → KEY COLON VALUE
    KEY                 → QUOTE CHARS QUOTE | QUOTE QUOTE
    VALUE               → null | true | false |
                          0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER | 
                          QUOTE CHARS QUOTE | QUOTE QUOTE | 
                          LEFT_CURLY_BRACKET PAIRS RIGHT_CURLY_BRACKET | LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
    CHARS               → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
                          a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
                          1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | CHAR CHARS
    INTEGER             → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER
    NUMERIC             → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    CHAR                → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
                          a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
                          1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
    LEFT_CURLY_BRACKET  → {
    RIGHT_CURLY_BRACKET → }
    QUOTE               → "
    COLON               → :
    COMMA               → ,
}
```

Finalmente, debemos descomponer los lados derechos de longitud mayor a dos en una cadena de producciones con lados derechos de dos variables. Notemos que las producciones que cuyo lado derecho tienen longitud mayor a dos son:
- `S → LEFT_CURLY_BRACKET PAIRS RIGHT_CURLY_BRACKET`
- `PAIRS → KEY COLON VALUE`
- `PAIRS → PAIR COMMA PAIRS`
- `KEY → QUOTE CHARS QUOTE`
- `KEY → QUOTE CHARS QUOTE`
- `VALUE → QUOTE CHARS QUOTE`
- `VALUE → LEFT_CURLY_BRACKET PAIRS RIGHT_CURLY_BRACKET`

Aplicando la limpieza, debemos construir las siguientes producciones `CHARS_QUOTE → CHARS QUOTE`; `COMMA_PAIRS → COMMA PAIRS`; `COLON_VALUE → COLON VALUE`; `PAIRS_RIGHT_CURLY_BRACKET → PAIRS RIGHT_CURLY_BRACKET`. Obtenemos las producciones:
```
P' = {
    S                   → LEFT_CURLY_BRACKET PAIRS_RIGHT_CURLY_BRACKET | LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
    PAIRS               → KEY COLON_VALUE | PAIR COMMA_PAIRS
    PAIR                → KEY COLON_VALUE
    KEY                 → QUOTE CHARS_QUOTE | QUOTE QUOTE
    VALUE               → null | true | false |
                          0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER | 
                          QUOTE CHARS_QUOTE | QUOTE QUOTE | 
                          LEFT_CURLY_BRACKET PAIRS_RIGHT_CURLY_BRACKET | LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
    CHARS               → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
                          a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
                          1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | CHAR CHARS
    INTEGER             → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER
    NUMERIC             → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    CHAR                → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
                          a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
                          1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
    LEFT_CURLY_BRACKET  → {
    RIGHT_CURLY_BRACKET → }
    QUOTE               → "
    COLON               → :
    COMMA               → ,
    CHARS_QUOTE → CHARS QUOTE
    COMMA_PAIRS → COMMA PAIRS
    COLON_VALUE → COLON VALUE
    PAIRS_RIGHT_CURLY_BRACKET → PAIRS RIGHT_CURLY_BRACKET
}
```

No obstante, si deseamos validar un string mediante el algoritmo CYK, precisamos separar cada token de las terminales `true`, `false` y `null`. Con ello, obtenemos las siguiente GLC modificada:

Sea G = ⟨T, V, P, S⟩, donde las terminales y producciones son:

```
T = {
    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p, q, r, s, t, u, v, w, x, y, z,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 0,
    {, }, "
}
```
```
P = {
    S                   → LEFT_CURLY_BRACKET PAIRS_RIGHT_CURLY_BRACKET | LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
    PAIRS               → KEY COLON_VALUE | PAIR COMMA_PAIRS
    PAIR                → KEY COLON_VALUE
    KEY                 → QUOTE CHARS_QUOTE | QUOTE QUOTE
    VALUE               → N_U L_L | T_R U_E | F A_L_S_E |
                          0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER | 
                          QUOTE CHARS_QUOTE | QUOTE QUOTE | 
                          LEFT_CURLY_BRACKET PAIRS_RIGHT_CURLY_BRACKET | LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
    CHARS               → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
                          a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
                          1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | CHAR CHARS
    INTEGER             → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER
    NUMERIC             → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
    CHAR                → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | 
                          a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 
                          1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
    LEFT_CURLY_BRACKET  → {
    RIGHT_CURLY_BRACKET → }
    QUOTE               → "
    COLON               → :
    COMMA               → ,
    CHARS_QUOTE → CHARS QUOTE
    COMMA_PAIRS → COMMA PAIRS
    COLON_VALUE → COLON VALUE
    PAIRS_RIGHT_CURLY_BRACKET → PAIRS RIGHT_CURLY_BRACKET
    N → n
    U → u
    L → l
    T → t
    R → r
    E → e
    F → f
    A → a
    S → s
    L_L → L L
    N_U → N U
    T_R → T R
    U_E → U E
    S_E → S E
    A_L → A L
    A_L_S_E → A_L S_E
}
```

## 6. Casos de pruebas
[WIP]
