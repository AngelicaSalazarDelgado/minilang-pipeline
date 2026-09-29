"""
Etapa 2 del pipeline. Lee programa.ir, valida el contrato y ejecuta
las operaciones con estilo funcional. Genera resultado.txt con la
traza, el resultado final y la cantidad de operaciones.

El nucleo no usa ciclos for ni while. FILTER usa filter(), MAP usa map()
y tanto REDUCE como la secuencia completa de operaciones usan reduce().

Uso: python3 ejecutor.py programa.ir resultado.txt
Codigos de salida, 0 correcto, 1 error de contrato o de ejecucion,
2 error de uso o de lectura de archivos.
"""

import operator
import sys
from functools import reduce
from pathlib import Path


class ErrorContrato(Exception):
    """programa.ir no cumple el formato acordado con Java."""


class ErrorEjecucion(Exception):
    """El programa es valido, pero no se puede ejecutar con estos datos."""


# Tablas que asocian cada simbolo con una funcion. Las funciones se usan
# como datos, asi se evita una cadena de if/else por cada operador.
COMPARADORES = {
    ">": operator.gt,
    "<": operator.lt,
    ">=": operator.ge,
    "<=": operator.le,
    "==": operator.eq,
}

ARITMETICOS = {
    "+": operator.add,
    "-": operator.sub,
    "*": operator.mul,
}

# SUM parte de 0, que es su elemento neutro, por eso funciona con listas vacias.
# MAX y MIN no tienen elemento neutro entre los enteros.
REDUCTORES = {
    "SUM": lambda datos: reduce(operator.add, datos, 0),
    "MAX": lambda datos: reduce(max, datos),
    "MIN": lambda datos: reduce(min, datos),
}


# Lectura y validacion del contrato

def a_entero(texto, numero_linea):
    """Convierte un campo a entero o genera un error de contrato con la linea."""
    try:
        return int(texto)
    except ValueError:
        raise ErrorContrato(f"linea {numero_linea}, '{texto}' no es un entero") from None


def parsear_linea(numero_linea, texto):
    """Convierte una linea de programa.ir en una tupla, por ejemplo ("FILTER", ">", 5).
    Cada formato valido del contrato tiene su propia condicion."""
    partes = texto.strip().split("|")
    nombre, cantidad = partes[0], len(partes)
    if nombre == "DATA" and cantidad == 2:
        return ("DATA", list(map(lambda t: a_entero(t, numero_linea), partes[1].split(","))))
    if nombre == "FILTER" and cantidad == 3 and partes[1] in COMPARADORES:
        return ("FILTER", partes[1], a_entero(partes[2], numero_linea))
    if nombre == "MAP" and cantidad == 3 and partes[1] in ARITMETICOS:
        return ("MAP", partes[1], a_entero(partes[2], numero_linea))
    if nombre == "REDUCE" and cantidad == 2 and partes[1] in REDUCTORES:
        return ("REDUCE", partes[1])
    if nombre == "PRINT" and cantidad == 1:
        return ("PRINT",)
    raise ErrorContrato(f"linea {numero_linea} no cumple el formato, '{texto.strip()}'")


def validar_estructura(instrucciones):
    """Revisa el orden, DATA al inicio, PRINT al final, al menos una operacion
    en medio y REDUCE solo como ultima operacion. Devuelve los datos y las operaciones.
    EJECUTORES se define mas abajo. Python busca el nombre al ejecutar la funcion,
    no al definirla, y esta funcion solo se llama desde main."""
    if not instrucciones or instrucciones[0][0] != "DATA":
        raise ErrorContrato("programa.ir debe iniciar con DATA")
    if instrucciones[-1][0] != "PRINT":
        raise ErrorContrato("programa.ir debe terminar con PRINT")
    operaciones = instrucciones[1:-1]
    if not operaciones or any(map(lambda op: op[0] not in EJECUTORES, operaciones)):
        raise ErrorContrato("entre DATA y PRINT debe haber al menos una operacion FILTER, MAP o REDUCE")
    if any(map(lambda op: op[0] == "REDUCE", operaciones[:-1])):
        raise ErrorContrato("REDUCE solo puede ser la ultima operacion")
    return instrucciones[0][1], operaciones


# Nucleo funcional. Ninguna funcion modifica la lista que recibe, siempre devuelve una nueva.

def ejecutar_filter(op, datos):
    """Conserva los elementos que cumplen la comparacion."""
    _, simbolo, valor = op
    comparar = COMPARADORES[simbolo]
    return list(filter(lambda x: comparar(x, valor), datos))


def ejecutar_map(op, datos):
    """Aplica la operacion aritmetica a cada elemento."""
    _, simbolo, valor = op
    operar = ARITMETICOS[simbolo]
    return list(map(lambda x: operar(x, valor), datos))


def ejecutar_reduce(op, datos):
    """Reduce la lista a un solo numero. MAX y MIN fallan con una lista vacia."""
    _, tipo = op
    if not datos and tipo != "SUM":
        raise ErrorEjecucion(f"REDUCE {tipo} sobre una lista vacia, no hay ningun valor que devolver")
    return REDUCTORES[tipo](datos)


# Cada nombre de operacion apunta a la funcion que la ejecuta.
# Cumple el mismo papel que el polimorfismo en Java.
EJECUTORES = {
    "FILTER": ejecutar_filter,
    "MAP": ejecutar_map,
    "REDUCE": ejecutar_reduce,
}


def describir(op):
    """Texto de la operacion para la traza, por ejemplo FILTER > 5."""
    return " ".join(map(str, op))


def formatear(valor):
    """Texto del valor para la traza, un numero o una lista entre corchetes."""
    if isinstance(valor, int):
        return str(valor)
    return "[" + ", ".join(map(str, valor)) + "]"


def aplicar(estado, op):
    """Recibe (valor, traza) y devuelve un estado nuevo, sin modificar el anterior."""
    valor, traza = estado
    nuevo = EJECUTORES[op[0]](op, valor)
    return (nuevo, traza + (f"{describir(op)} => {formatear(nuevo)}",))


def ejecutar(datos, operaciones):
    # La secuencia completa de operaciones tambien es un reduce.
    # El acumulador es el estado, que parte de los datos y una traza vacia.
    return reduce(aplicar, operaciones, (datos, ()))


def valor_para_contrato(valor):
    """Texto de RESULT= para MIPS, un numero o una secuencia separada por comas."""
    if isinstance(valor, int):
        return str(valor)
    return ",".join(map(str, valor))


# Programa principal

def fallar(mensaje, salida):
    """Muestra el error, borra la salida anterior y devuelve el codigo 1."""
    print(mensaje, file=sys.stderr)
    # Se borra un resultado.txt anterior para que MIPS no procese uno viejo
    salida.unlink(missing_ok=True)
    return 1


def main(argv):
    """Lee, valida, ejecuta y escribe resultado.txt solo si todo salio bien."""
    if len(argv) != 3:
        print("Uso: python3 ejecutor.py programa.ir resultado.txt", file=sys.stderr)
        return 2
    entrada, salida = Path(argv[1]), Path(argv[2])
    try:
        lineas = entrada.read_text(encoding="utf-8").splitlines()
        instrucciones = list(map(parsear_linea, range(1, len(lineas) + 1), lineas))
        datos, operaciones = validar_estructura(instrucciones)
        resultado, traza = ejecutar(datos, operaciones)
    except ErrorContrato as e:
        return fallar(f"Error de contrato en programa.ir, {e}", salida)
    except ErrorEjecucion as e:
        return fallar(f"Error de ejecucion, {e}", salida)
    except OSError as e:
        print(f"Error de archivo, {e}", file=sys.stderr)
        return 2

    contenido = traza + (f"RESULT={valor_para_contrato(resultado)}", f"OPS={len(operaciones)}")
    salida.write_text("\n".join(contenido) + "\n", encoding="utf-8")
    print("\n".join(contenido))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
