package minilang;

// Las palabras existen pero el orden no respeta la gramatica, por ejemplo falta DATA
public class ErrorSintactico extends ErrorMiniLang {
    public ErrorSintactico(int linea, String detalle) {
        super("sintactico", linea, detalle);
    }
}
