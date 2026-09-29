package minilang;

/*
 * Unidad minima con significado que el lexer entrega al parser.
 * El tipo sirve para decidir, el lexema conserva el texto original
 * y la linea permite reportar errores.
 */
public class Token {
    private final TokenType tipo;
    private final String lexema;
    private final int linea;

    public Token(TokenType tipo, String lexema, int linea) {
        this.tipo = tipo;
        this.lexema = lexema;
        this.linea = linea;
    }

    public TokenType getTipo() { return tipo; }
    public String getLexema() { return lexema; }
    public int getLinea() { return linea; }

    // Sobrescribe el toString de Object. %-12s rellena el tipo a 12 caracteres para alinear columnas
    @Override
    public String toString() {
        return String.format("linea %d  %-12s %s", linea, tipo, lexema);
    }
}
