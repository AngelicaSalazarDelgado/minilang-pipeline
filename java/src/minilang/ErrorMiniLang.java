package minilang;

/*
 * Clase base de todos los errores del analisis. Guarda la linea y arma el
 * mensaje con un formato unico. Cada subclase solo indica la fase.
 * Extiende Exception, asi el compilador obliga a declararla o atraparla.
 */
public class ErrorMiniLang extends Exception {
    private final int linea;

    public ErrorMiniLang(String fase, int linea, String detalle) {
        super("Error " + fase + " en linea " + linea + ", " + detalle);
        this.linea = linea;
    }

    public int getLinea() { return linea; }
}
