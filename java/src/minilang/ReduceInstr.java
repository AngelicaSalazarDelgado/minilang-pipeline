package minilang;

// <reduce> ::= "REDUCE" ("SUM" | "MAX" | "MIN")   se traduce a   REDUCE|tipo
public class ReduceInstr extends Operacion {
    private final String tipo;

    public ReduceInstr(int linea, String tipo) {
        super("REDUCE", linea);
        this.tipo = tipo;
    }

    @Override
    public String toIR() {
        return "REDUCE|" + tipo;
    }

    // Despues de REDUCE el resultado deja de ser una lista y pasa a ser un numero
    @Override
    public boolean produceEscalar() { return true; }
}
