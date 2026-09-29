package minilang;

// Aparece un simbolo o palabra que no existe en el lenguaje, por ejemplo %
public class ErrorLexico extends ErrorMiniLang {
    public ErrorLexico(int linea, String detalle) {
        super("lexico", linea, detalle);
    }
}
