package minilang;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/*
 * Analizador sintactico descendente recursivo.
 * Hay un metodo por cada no terminal de la gramatica, asi que la
 * gramatica se puede leer directamente en el codigo. Las repeticiones { }
 * se implementan con ciclos while. Si la gramatica tuviera estructuras
 * anidadas, estos metodos se llamarian a si mismos de forma recursiva.
 */
public class Parser {

    private static final Set<TokenType> COMPARADORES = EnumSet.of(
            TokenType.MAYOR, TokenType.MENOR, TokenType.MAYOR_IGUAL,
            TokenType.MENOR_IGUAL, TokenType.IGUAL_IGUAL);
    private static final Set<TokenType> ARITMETICOS = EnumSet.of(
            TokenType.MAS, TokenType.MENOS, TokenType.POR);
    private static final Set<TokenType> REDUCCIONES = EnumSet.of(
            TokenType.SUM, TokenType.MAX, TokenType.MIN);
    private static final Set<TokenType> INICIO_OPERACION = EnumSet.of(
            TokenType.FILTER, TokenType.MAP, TokenType.REDUCE);

    private final List<Token> tokens;
    private int pos = 0;

    public Parser(List<Token> tokens) {
        this.tokens = tokens;
    }

    // <programa> ::= <data> <operacion> { <operacion> } "PRINT"
    public List<Instruccion> parsePrograma() throws ErrorSintactico {
        List<Instruccion> programa = new ArrayList<>();
        programa.add(parseData());
        programa.add(parseOperacion());
        // { <operacion> }, se repite mientras el siguiente token inicie una operacion
        while (INICIO_OPERACION.contains(actual().getTipo())) {
            programa.add(parseOperacion());
        }
        Token print = esperar(TokenType.PRINT, "FILTER, MAP, REDUCE o PRINT");
        programa.add(new PrintInstr(print.getLinea()));
        if (actual().getTipo() != TokenType.EOF) {
            throw error("no se permiten instrucciones despues de PRINT");
        }
        return programa;
    }

    // <data> ::= "DATA" <numero> { <numero> }
    private Instruccion parseData() throws ErrorSintactico {
        Token data = esperar(TokenType.DATA, "DATA al inicio del programa");
        List<Integer> valores = new ArrayList<>();
        valores.add(parseNumero());
        // { <numero> }, se repite mientras haya numeros
        while (actual().getTipo() == TokenType.NUMERO) {
            valores.add(parseNumero());
        }
        return new DataInstr(data.getLinea(), valores);
    }

    // <operacion> ::= <filter> | <map> | <reduce>
    // Unico lugar donde se decide que tipo de objeto crear, corresponde a la alternativa | de la gramatica
    private Instruccion parseOperacion() throws ErrorSintactico {
        switch (actual().getTipo()) {
            case FILTER: return parseFilter();
            case MAP:    return parseMap();
            case REDUCE: return parseReduce();
            default:     throw errorEsperado("FILTER, MAP o REDUCE");
        }
    }

    // <filter> ::= "FILTER" <comparador> <numero>
    private Instruccion parseFilter() throws ErrorSintactico {
        Token filter = avanzar();
        Token comparador = esperarUno(COMPARADORES, "un comparador (>, <, >=, <=, ==)");
        int valor = parseNumero();
        return new FilterInstr(filter.getLinea(), comparador.getLexema(), valor);
    }

    // <map> ::= "MAP" <aritmetico> <numero>
    private Instruccion parseMap() throws ErrorSintactico {
        Token map = avanzar();
        Token operador = esperarUno(ARITMETICOS, "un operador aritmetico (+, -, *)");
        int valor = parseNumero();
        return new MapInstr(map.getLinea(), operador.getLexema(), valor);
    }

    // <reduce> ::= "REDUCE" ("SUM" | "MAX" | "MIN")
    private Instruccion parseReduce() throws ErrorSintactico {
        Token reduce = avanzar();
        Token tipo = esperarUno(REDUCCIONES, "SUM, MAX o MIN");
        return new ReduceInstr(reduce.getLinea(), tipo.getLexema());
    }

    // <numero> ::= entero no negativo, el lexer ya lo entrega como un solo token.
    // parseInt no puede fallar porque el lexer ya valido que el numero cabe en un int.
    private int parseNumero() throws ErrorSintactico {
        Token numero = esperar(TokenType.NUMERO, "un numero");
        return Integer.parseInt(numero.getLexema());
    }

    // Metodos auxiliares

    // Token que se esta analizando, sin consumirlo
    private Token actual() {
        return tokens.get(pos);
    }

    // Consume el token actual. En EOF no avanza, para no salir de la lista
    private Token avanzar() {
        Token t = tokens.get(pos);
        if (t.getTipo() != TokenType.EOF) {
            pos++;
        }
        return t;
    }

    // Exige un tipo de token exacto. Si no coincide, genera el error con la linea
    private Token esperar(TokenType tipo, String esperado) throws ErrorSintactico {
        if (actual().getTipo() != tipo) {
            throw errorEsperado(esperado);
        }
        return avanzar();
    }

    // Igual que esperar, pero acepta cualquiera de un conjunto de tipos
    private Token esperarUno(Set<TokenType> tipos, String esperado) throws ErrorSintactico {
        if (!tipos.contains(actual().getTipo())) {
            throw errorEsperado(esperado);
        }
        return avanzar();
    }

    private ErrorSintactico errorEsperado(String esperado) {
        return error("se esperaba " + esperado + " y se encontro " + describir(actual()));
    }

    private ErrorSintactico error(String detalle) {
        return new ErrorSintactico(actual().getLinea(), detalle);
    }

    private String describir(Token t) {
        return t.getTipo() == TokenType.EOF ? "el fin del archivo" : "'" + t.getLexema() + "'";
    }
}
