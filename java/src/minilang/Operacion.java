package minilang;

// Representa <operacion> de la gramatica, agrupa FILTER, MAP y REDUCE
public abstract class Operacion extends Instruccion {

    protected Operacion(String nombre, int linea) {
        super(nombre, linea);
    }

    // Toda operacion trabaja sobre una lista
    @Override
    public boolean requiereLista() { return true; }
}
