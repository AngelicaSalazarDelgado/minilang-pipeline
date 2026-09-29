package minilang;

// <filter> ::= "FILTER" <comparador> <numero>   se traduce a   FILTER|comparador|n
public class FilterInstr extends Operacion {
    private final String comparador;
    private final int valor;

    public FilterInstr(int linea, String comparador, int valor) {
        super("FILTER", linea);
        this.comparador = comparador;
        this.valor = valor;
    }

    @Override
    public String toIR() {
        return "FILTER|" + comparador + "|" + valor;
    }
}
