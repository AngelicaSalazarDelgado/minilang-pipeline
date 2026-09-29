package minilang;

/*
 * Catalogo de categorias de token. Cada valor corresponde a un simbolo
 * terminal de la gramatica, excepto EOF, que marca el fin del archivo.
 */
public enum TokenType {
    // Palabras clave
    DATA, FILTER, MAP, REDUCE, PRINT,
    // Tipos de reduccion
    SUM, MAX, MIN,
    // Comparadores
    MAYOR, MENOR, MAYOR_IGUAL, MENOR_IGUAL, IGUAL_IGUAL,
    // Operadores aritmeticos
    MAS, MENOS, POR,
    // Literales y fin de archivo
    NUMERO, EOF
}
