package minilang;

// <map> ::= "MAP" <aritmetico> <numero>   se traduce a   MAP|operador|n
public class MapInstr extends Operacion {
    private final String operador;
    private final int valor;

    public MapInstr(int linea, String operador, int valor) {
        super("MAP", linea);
        this.operador = operador;
        this.valor = valor;
    }

    @Override
    public String toIR() {
        return "MAP|" + operador + "|" + valor;
    }
}
