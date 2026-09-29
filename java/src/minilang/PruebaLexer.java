package minilang;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;

// Herramienta de depuracion. Imprime los tokens de un archivo .mini sin ejecutar el resto del pipeline
public class PruebaLexer {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Uso: java minilang.PruebaLexer archivo.mini");
            System.exit(2);
        }
        try {
            String fuente = Files.readString(Path.of(args[0]));
            List<Token> tokens = new Lexer(fuente).tokenizar();
            for (Token t : tokens) {
                System.out.println(t);
            }
        } catch (ErrorMiniLang e) {
            System.err.println(e.getMessage());
            System.exit(1);
        } catch (IOException e) {
            System.err.println("No se pudo leer el archivo " + args[0]);
            System.exit(2);
        }
    }
}
