import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import io.openapiprocessor.jackson.JacksonConverter;
import io.openapiprocessor.jsonschema.reader.UriReader;
import io.openapiprocessor.jsonschema.schema.DocumentLoader;
import io.openapiprocessor.jsonschema.schema.JsonInstance;
import io.openapiprocessor.jsonschema.schema.JsonSchema;
import io.openapiprocessor.jsonschema.schema.SchemaStore;
import io.openapiprocessor.jsonschema.schema.SchemaVersion;
import io.openapiprocessor.jsonschema.validator.Validator;
import io.openapiprocessor.jsonschema.validator.ValidatorSettings;
import java.net.URI;
import java.util.Map;

/**
 * The jsonschema-benchmark entry point for openapiprocessor json-schema-validator: read the instances into memory, parse each (timed), compile the
 * schema (timed), validate every instance once cold, warm up, validate once more warm. Prints
 * "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
 */
public final class Main {
    static final long WARMUP_ITERATIONS = 100;
    static final long MAX_WARMUP_TIME = 10_000_000_000L;

    static final JacksonConverter CONVERTER = new JacksonConverter();

    record Compiled(Validator validator, JsonSchema schema) {}

    static JsonInstance parse(String line) throws Exception {
        return new JsonInstance(CONVERTER.convert(line));
    }

    static Compiled compile(String schemaText) throws Exception {
        Object document = CONVERTER.convert(schemaText);
        String uri = document instanceof Map<?, ?> map && map.get("$schema") instanceof String s ? s : "";
        SchemaVersion version = switch (uri.replaceAll("#$", "")) {
            case "https://json-schema.org/draft/2019-09/schema" -> SchemaVersion.Draft201909;
            case "http://json-schema.org/draft-07/schema" -> SchemaVersion.Draft7;
            default -> SchemaVersion.Draft202012;
        };
        SchemaStore store = new SchemaStore(new DocumentLoader(new UriReader(), CONVERTER));
        store.registerDraft202012();
        store.registerDraft201909();
        store.registerDraft7();
        URI schemaUri = store.register(document);
        ValidatorSettings settings = new ValidatorSettings();
        settings.setVersion(version);
        return new Compiled(new Validator(settings), store.getSchema(schemaUri, version));
    }

    static boolean isValid(Compiled compiled, JsonInstance instance) {
        return compiled.validator().validate(compiled.schema(), instance).isValid();
    }

    static boolean validateAll(Compiled validator, JsonInstance[] instances, boolean report) throws Exception {
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
        JsonInstance[] instances = new JsonInstance[lines.size()];
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
