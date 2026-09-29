package minilang;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;

/*
 * Etapa 1 del pipeline. Lee programa.mini, lo valida en tres fases
 * y genera programa.ir solo si el programa es valido.
 * Codigos de salida, 0 correcto, 1 error en el programa .mini,
 * 2 error de uso o de lectura de archivos.
 */
public class Main {

    public static void main(String[] args) {
        if (args.length != 2) {
            System.err.println("Uso: java minilang.Main entrada.mini salida.ir");
            System.exit(2);
        }
        Path entrada = Path.of(args[0]);
        Path salida = Path.of(args[1]);

        try {
            String fuente = Files.readString(entrada);

            List<Token> tokens = new Lexer(fuente).tokenizar();               // fase lexica
            List<Instruccion> programa = new Parser(tokens).parsePrograma();  // fase sintactica
            new AnalizadorSemantico().verificar(programa);                    // fase semantica

            // Generacion de IR, solo se llega aqui si no hubo errores
            List<String> lineas = new ArrayList<>();
            for (Instruccion i : programa) {
                lineas.add(i.toIR());   // polimorfismo, cada subclase genera su propia linea
            }
            Files.write(salida, lineas);
            System.out.println("OK, " + programa.size() + " instrucciones traducidas a " + salida);

        } catch (ErrorMiniLang e) {
            System.err.println(e.getMessage());
            borrarSalidaVieja(salida);
            System.exit(1);
        } catch (IOException e) {
            System.err.println("Error de archivo, " + e.getMessage());
            System.exit(2);
        }
    }

    // Si hubo error se borra un programa.ir anterior para que Python no ejecute uno viejo
    private static void borrarSalidaVieja(Path salida) {
        try {
            Files.deleteIfExists(salida);
        } catch (IOException e) {
            System.err.println("No se pudo borrar " + salida);
        }
    }
}
