package minilang;

/*
 * Clase base de todas las instrucciones del programa.
 * Cada subclase sabe traducirse a su linea de representacion intermedia.
 */
public abstract class Instruccion {
    private final String nombre;
    private final int linea;

    protected Instruccion(String nombre, int linea) {
        this.nombre = nombre;
        this.linea = linea;
    }

    public String getNombre() { return nombre; }
    public int getLinea() { return linea; }

    // Cada subclase define su propia traduccion a IR
    public abstract String toIR();

    // Por defecto una instruccion no trabaja sobre la lista ni la convierte en numero.
    // Las subclases que lo necesiten sobrescriben estos metodos. Los usa el analizador
    // semantico, asi no necesita preguntar el tipo de cada instruccion con instanceof.
    public boolean requiereLista() { return false; }
    public boolean produceEscalar() { return false; }
}
