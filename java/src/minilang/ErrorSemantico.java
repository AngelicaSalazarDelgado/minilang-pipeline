package minilang;

// La estructura es correcta pero no tiene sentido, por ejemplo MAP despues de REDUCE
public class ErrorSemantico extends ErrorMiniLang {
    public ErrorSemantico(int linea, String detalle) {
        super("semantico", linea, detalle);
    }
}
