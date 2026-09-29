package minilang;

import java.util.ArrayList;
import java.util.List;

// <data> ::= "DATA" <numero> { <numero> }   se traduce a   DATA|n1,n2,...
public class DataInstr extends Instruccion {
    private final List<Integer> valores;

    public DataInstr(int linea, List<Integer> valores) {
        super("DATA", linea);
        this.valores = valores;
    }

    @Override
    public String toIR() {
        List<String> textos = new ArrayList<>();
        for (int v : valores) {
            textos.add(String.valueOf(v));
        }
        return "DATA|" + String.join(",", textos);
    }
}
