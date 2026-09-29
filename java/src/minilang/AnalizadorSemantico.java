package minilang;

import java.util.List;

/*
 * Revisa reglas de significado que la gramatica no puede expresar.
 * Regla, despues de REDUCE el valor es un numero, asi que ya no se puede
 * aplicar otra operacion de listas (FILTER, MAP ni otro REDUCE).
 * No pregunta el tipo de cada instruccion, usa los metodos polimorficos
 * requiereLista y produceEscalar.
 */
public class AnalizadorSemantico {

    public void verificar(List<Instruccion> programa) throws ErrorSemantico {
        boolean esEscalar = false;
        for (Instruccion i : programa) {
            if (esEscalar && i.requiereLista()) {
                throw new ErrorSemantico(i.getLinea(),
                        i.getNombre() + " no se puede aplicar despues de REDUCE, el valor ya no es una lista");
            }
            if (i.produceEscalar()) {
                esEscalar = true;
            }
        }
    }
}
