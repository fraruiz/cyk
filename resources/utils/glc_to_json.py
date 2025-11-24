import re
import json

def parse_production_rule(rule_line, is_start_symbol):
    """
    Parsea una línea de producción de GLC (ej: 'A -> BC | d') en una lista de diccionarios FNC.
    """
    productions = []
    
    # Separar el símbolo izquierdo (LEFT_SYMBOL) de las reglas (RIGHT_SYMBOLS)
    try:
        left_symbol, right_part = rule_line.split("→", 1)
        left_symbol = left_symbol.strip()
    except ValueError:
        print(f"Advertencia: Línea de regla inválida: {rule_line}")
        return []

    # Separar las reglas alternativas (|)
    right_rules = [r.strip() for r in right_part.split('|')]
    
    # Procesar cada regla derecha
    for rule in right_rules:
        rule_parts = rule.split()  # Separar por espacios
        
        # 1. Regla Terminal (A -> a) - TYPE 1
        if len(rule_parts) == 1 and rule_parts[0].islower() or rule_parts[0] in ['{', '}', ':', ',', '"'] or rule_parts[0] in ['null', 'true', 'false'] or rule_parts[0].isdigit():
            
            # Manejar terminales multilenguaje si no han sido descompuestos
            if rule_parts[0] in ['null', 'true', 'false']:
                 # Por simplicidad, asumimos que estos *deberían* haber sido descompuestos
                 # y tratamos este caso solo si la regla es puramente terminal.
                 pass

            productions.append({
                "START": is_start_symbol,
                "LEFT_SYMBOL": left_symbol,
                "FIRST_RIGHT_SYMBOL": rule_parts[0],
                "SECOND_RIGHT_SYMBOL": None,
                "TYPE": "1"
            })
            
        # 2. Regla No Terminal (A -> BC) - TYPE 2
        elif len(rule_parts) == 2:
            productions.append({
                "START": is_start_symbol,
                "LEFT_SYMBOL": left_symbol,
                "FIRST_RIGHT_SYMBOL": rule_parts[0],
                "SECOND_RIGHT_SYMBOL": rule_parts[1],
                "TYPE": "2"
            })

        # 3. Regla Simple de un solo NT, que actúa como terminal (ej: CHARS -> A)
        # Esto solo se aplica si el NT en la derecha es un solo carácter o dígito,
        # lo que indica una regla unitaria no terminal, que en FNC se evita. 
        # Pero en esta gramática, 'CHARS -> A' es una simplificación de FNC.
        elif len(rule_parts) == 1 and rule_parts[0].isupper() or rule_parts[0].isdigit():
             productions.append({
                "START": is_start_symbol,
                "LEFT_SYMBOL": left_symbol,
                "FIRST_RIGHT_SYMBOL": rule_parts[0],
                "SECOND_RIGHT_SYMBOL": None,
                "TYPE": "1"
            })
            
        # 4. Error o Regla no FNC (longitud > 2)
        else:
            print(f"Advertencia: La regla '{rule}' de '{left_symbol}' no parece cumplir FNC (longitud {len(rule_parts)} o formato incorrecto) y se omite.")

    return productions

def convert_grammar_to_json(grammar_text):
    """
    Convierte todo el bloque de texto de la gramática a la estructura JSON.
    """
    grammar_list = []
    
    # Limpiar el texto, reemplazar saltos de línea y eliminar espacios extra
    # y dividir por líneas
    cleaned_text = re.sub(r'\s{2,}', ' ', grammar_text.strip())
    lines = [line.strip() for line in cleaned_text.split('\n') if line.strip()]

    # El símbolo de inicio (S) es el primero definido.
    start_symbol = "S"

    for line in lines:
        # Reemplazar la flecha (puede ser '->' o '→')
        line = line.replace('->', '→')
        
        # Eliminar comentarios de línea y espacios sobrantes
        line = line.split('#')[0].strip() 
        if not line:
            continue
            
        # Determinar si es el símbolo de inicio
        is_start = line.startswith(start_symbol + ' ') or line.startswith(start_symbol + '→')
        
        # Parsear la línea
        grammar_list.extend(parse_production_rule(line, is_start))
        
    return grammar_list

# ----------------------------------------------------------------------------------
# GRAMÁTICA DE ENTRADA (Como una cadena de texto)
# ----------------------------------------------------------------------------------

grammar_input = """
S → LEFT_CURLY_BRACKET PAIRS_RIGHT_CURLY_BRACKET | LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
PAIRS → KEY COLON_VALUE | PAIR COMMA_PAIRS
PAIR → KEY COLON_VALUE
KEY → QUOTE CHARS_QUOTE | QUOTE QUOTE
VALUE → N_U L_L | T_R U_E | F A_L_S_E | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER |  QUOTE CHARS_QUOTE | QUOTE QUOTE |  LEFT_CURLY_BRACKET PAIRS_RIGHT_CURLY_BRACKET | LEFT_CURLY_BRACKET RIGHT_CURLY_BRACKET
CHARS → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 | CHAR CHARS
INTEGER → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | NUMERIC INTEGER
NUMERIC → 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
CHAR → A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R | S | T | U | V | W | X | Y | Z | a | b | c | d | e | f | g | h | i | j | k | l | m | n | o | p | q | r | s | t | u | v | w | x | y | z | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0
LEFT_CURLY_BRACKET → {
RIGHT_CURLY_BRACKET → }
QUOTE → "
COLON → :
COMMA → ,
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
"""

# ----------------------------------------------------------------------------------
# EJECUCIÓN
# ----------------------------------------------------------------------------------

json_output = convert_grammar_to_json(grammar_input)

# Imprimir el JSON resultante
print("--- JSON RESULTANTE ---")
print(json.dumps(json_output, indent=4))

# ----------------------------------------------------------------------------------
# GUARDADO
# ----------------------------------------------------------------------------------

# 1. Definir el nombre del archivo
file_name = "./migrations/glc.json"

# 2. Guardar el resultado en el archivo JSON
try:
    with open(file_name, 'w', encoding='utf-8') as f:
        json.dump(json_output, f, indent=4, ensure_ascii=False)
    
    print(f"✅ ¡Éxito! La gramática ha sido guardada en '{file_name}'.")

except IOError as e:
    print(f"❌ Error al intentar escribir el archivo '{file_name}': {e}")