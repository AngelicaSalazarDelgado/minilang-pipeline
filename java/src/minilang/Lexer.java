package minilang;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/*
 * Analizador lexico. Recorre el texto y en cada posicion prueba las
 * expresiones regulares que definen cada categoria de token.
 * No valida el orden de las instrucciones, eso le toca al parser.
 */
public class Lexer {

    // Expresiones regulares de cada categoria lexica.
    // No se usa \s para espacios porque incluye el salto de linea, que se necesita para contar lineas.
    private static final Pattern SALTO   = Pattern.compile("\\n");
    private static final Pattern ESPACIO = Pattern.compile("[ \\t\\r]+");
    private static final Pattern NUMERO  = Pattern.compile("[0-9]+");
    private static final Pattern PALABRA = Pattern.compile("[A-Za-z]+");
    // Los simbolos de dos caracteres (>=, <=, ==) van antes que los de uno
    // para tomar siempre la coincidencia mas larga
    private static final Pattern SIMBOLO = Pattern.compile(">=|<=|==|[<>+\\-*]");

    private static final Map<String, TokenType> PALABRAS_CLAVE = Map.of(
            "DATA", TokenType.DATA,
            "FILTER", TokenType.FILTER,
            "MAP", TokenType.MAP,
            "REDUCE", TokenType.REDUCE,
            "PRINT", TokenType.PRINT,
            "SUM", TokenType.SUM,
            "MAX", TokenType.MAX,
            "MIN", TokenType.MIN);

    private static final Map<String, TokenType> SIMBOLOS = Map.of(
            ">=", TokenType.MAYOR_IGUAL,
            "<=", TokenType.MENOR_IGUAL,
            "==", TokenType.IGUAL_IGUAL,
            ">", TokenType.MAYOR,
            "<", TokenType.MENOR,
            "+", TokenType.MAS,
            "-", TokenType.MENOS,
            "*", TokenType.POR);

    private final String fuente;
    private int pos = 0;
    private int linea = 1;
    private String ultimo;   // texto reconocido por el ultimo patron que coincidio

    public Lexer(String fuente) {
        this.fuente = fuente;
    }

    // El orden de los if importa. Primero saltos y espacios, despues numeros,
    // palabras y simbolos. Si ningun patron coincide, el caracter no pertenece al lenguaje.
    public List<Token> tokenizar() throws ErrorLexico {
        List<Token> tokens = new ArrayList<>();
        while (pos < fuente.length()) {
            if (reconocer(SALTO)) {
                linea++;
            } else if (reconocer(ESPACIO)) {
                // los espacios solo separan tokens, se ignoran
            } else if (reconocer(NUMERO)) {
                tokens.add(crearNumero(ultimo));
            } else if (reconocer(PALABRA)) {
                tokens.add(crearPalabra(ultimo));
            } else if (reconocer(SIMBOLO)) {
                tokens.add(new Token(SIMBOLOS.get(ultimo), ultimo, linea));
            } else {
                throw new ErrorLexico(linea, "simbolo no reconocido '" + fuente.charAt(pos) + "'");
            }
        }
        // EOF lleva la linea del ultimo token para que los errores de fin de archivo sean claros
        int lineaFinal = tokens.isEmpty() ? 1 : tokens.get(tokens.size() - 1).getLinea();
        tokens.add(new Token(TokenType.EOF, "", lineaFinal));
        return tokens;
    }

    // Prueba el patron justo en la posicion actual (lookingAt no busca mas adelante).
    // Si coincide, guarda el texto reconocido y avanza la posicion.
    private boolean reconocer(Pattern patron) {
        Matcher m = patron.matcher(fuente);
        m.region(pos, fuente.length());
        if (m.lookingAt()) {
            ultimo = m.group();
            pos = m.end();
            return true;
        }
        return false;
    }

    // Valida que el numero quepa en un int, asi el parser puede convertirlo sin riesgo
    private Token crearNumero(String texto) throws ErrorLexico {
        try {
            Integer.parseInt(texto);
        } catch (NumberFormatException e) {
            throw new ErrorLexico(linea, "numero fuera de rango '" + texto + "'");
        }
        return new Token(TokenType.NUMERO, texto, linea);
    }

    // Solo se aceptan las palabras clave, y en mayuscula
    private Token crearPalabra(String texto) throws ErrorLexico {
        TokenType tipo = PALABRAS_CLAVE.get(texto);
        if (tipo == null) {
            throw new ErrorLexico(linea, "palabra no reconocida '" + texto + "'");
        }
        return new Token(tipo, texto, linea);
    }
}
