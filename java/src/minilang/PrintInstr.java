package minilang;

// "PRINT" cierra el programa   se traduce a   PRINT
public class PrintInstr extends Instruccion {

    public PrintInstr(int linea) {
        super("PRINT", linea);
    }

    @Override
    public String toIR() {
        return "PRINT";
    }
}
