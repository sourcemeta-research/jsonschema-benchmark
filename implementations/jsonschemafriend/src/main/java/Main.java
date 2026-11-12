import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import com.fasterxml.jackson.databind.ObjectMapper;
import net.jimblackler.jsonschemafriend.Schema;
import net.jimblackler.jsonschemafriend.SchemaStore;
import net.jimblackler.jsonschemafriend.ValidationException;
import net.jimblackler.jsonschemafriend.Validator;

/**
 * The jsonschema-benchmark entry point for jsonschemafriend: read the instances into memory, parse each (timed), compile the
 * schema (timed), validate every instance once cold, warm up, validate once more warm. Prints
 * "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
 */
public final class Main {
    static final long WARMUP_ITERATIONS = 100;
    static final long MAX_WARMUP_TIME = 10_000_000_000L;

    static final ObjectMapper MAPPER = new ObjectMapper();

    record Compiled(Validator validator, Schema schema) {}

    // jsonschemafriend validates plain Java maps, lists and values.
    static Object parse(String line) throws Exception {
        return MAPPER.readValue(line, Object.class);
    }

    static Compiled compile(String schemaText) throws Exception {
        return new Compiled(new Validator(), new SchemaStore().loadSchemaJson(schemaText));
    }

    static boolean isValid(Compiled compiled, Object instance) {
        try {
            compiled.validator().validate(compiled.schema(), instance);
            return true;
        } catch (ValidationException e) {
            return false;
        }
    }

    static boolean validateAll(Compiled validator, Object[] instances, boolean report) throws Exception {
        boolean valid = true;
        for (int i = 0; i < instances.length; i++) {
            if (!isValid(validator, instances[i])) {
                if (report) {
                    System.err.println("Error validating instance " + i);
                }
                valid = false;
            }
        }
        return valid;
    }

    public static void main(String[] args) throws Exception {
        if (args.length != 2) {
            System.err.println("Usage: Main <schema.json> <instances.jsonl>");
            System.exit(1);
        }
        String schemaText = Files.readString(Paths.get(args[0]));
        List<String> lines = Files.readAllLines(Paths.get(args[1])).stream().filter(l -> !l.isBlank()).toList();

        long parseStart = System.nanoTime();
        Object[] instances = new Object[lines.size()];
        for (int i = 0; i < instances.length; i++) {
            instances[i] = parse(lines.get(i));
        }
        long parseEnd = System.nanoTime();

        long compileStart = System.nanoTime();
        Compiled validator = compile(schemaText);
        long compileEnd = System.nanoTime();

        long coldStart = System.nanoTime();
        boolean valid = validateAll(validator, instances, true);
        long coldEnd = System.nanoTime();

        long cold = coldEnd - coldStart;
        long iterations = 1 + (MAX_WARMUP_TIME - 1) / Math.max(cold, 1);
        for (long i = 0; i < Math.min(iterations, WARMUP_ITERATIONS); i++) {
            validateAll(validator, instances, false);
        }

        long warmStart = System.nanoTime();
        validateAll(validator, instances, false);
        long warmEnd = System.nanoTime();

        System.out.println(cold + "," + (warmEnd - warmStart) + "," + (compileEnd - compileStart) + ","
                + (parseEnd - parseStart));
        System.exit(valid ? 0 : 1);
    }
}
