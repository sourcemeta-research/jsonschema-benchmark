package io.github.sourcemeta;

import dev.harrel.jsonschema.Validator;
import dev.harrel.jsonschema.ValidatorFactory;
import java.io.IOException;
import java.lang.Math;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;

public class App {
    static int WARMUP_ITERATIONS = 1000;
    static long MAX_WARMUP_TIME = (long) 1e9 * 10;

    public static boolean validateAll(Validator validator, URI schemaUri, List<String> docs) {
        boolean valid = true;
        for (String doc : docs) {
            Validator.Result result = validator.validate(schemaUri, doc);
            if (!result.isValid()) {
                valid = false;
            }
        }
        return valid;
    }

    public static void main(String[] args) throws IOException {
        Validator validator = new ValidatorFactory().createValidator();
        String schema = new String(Files.readAllBytes(Paths.get(args[0])));

        // Register the schema
        Long compileStart = System.nanoTime();
        URI schemaUri = validator.registerSchema(schema);
        Long compileEnd = System.nanoTime();

        List<String> docs = Files.readAllLines(Paths.get(args[1]));

        Long coldStart = System.nanoTime();
        boolean valid = validateAll(validator, schemaUri, docs);
        Long coldEnd = System.nanoTime();

        if (!valid) {
            System.exit(1);
        }

        // Warmup
        long iterations = (long) Math.ceil(((double) MAX_WARMUP_TIME) / (coldEnd - coldStart));
        for (int i = 0; i < WARMUP_ITERATIONS; i++) {
            validateAll(validator, schemaUri, docs);
        }

        Long warmStart = System.nanoTime();
        validateAll(validator, schemaUri, docs);
        Long warmEnd = System.nanoTime();

        System.out.println((coldEnd - coldStart) + "," + (warmEnd - warmStart) + "," + (compileEnd - compileStart));
    }
}
