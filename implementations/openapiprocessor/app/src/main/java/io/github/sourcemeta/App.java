package io.github.sourcemeta;

// import dev.harrel.jsonschema.Validator;
// import dev.harrel.jsonschema.ValidatorFactory;
// import java.lang.Math;
// import java.net.URI;

import io.openapiprocessor.interfaces.Converter;
import io.openapiprocessor.interfaces.ConverterException;
import io.openapiprocessor.jackson.JacksonConverter;
import io.openapiprocessor.jsonschema.reader.UriReader;
import io.openapiprocessor.jsonschema.schema.DocumentLoader;
import io.openapiprocessor.jsonschema.schema.JsonInstance;
import io.openapiprocessor.jsonschema.schema.JsonSchema;
import io.openapiprocessor.jsonschema.schema.SchemaStore;
import io.openapiprocessor.jsonschema.validator.Validator;
import io.openapiprocessor.jsonschema.validator.ValidatorSettings;
import io.openapiprocessor.jsonschema.validator.steps.ValidationStep;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;

public class App {
  static int WARMUP_ITERATIONS = 1000;
  static long MAX_WARMUP_TIME = (long) 1e9 * 10;

  public static boolean validateAll(
      Validator validator, JsonSchema schema, List<JsonInstance> docs) {
    boolean valid = true;
    ValidationStep step;
    for (JsonInstance doc : docs) {
      step = validator.validate(schema, doc);
      if (!step.isValid()) {
        valid = false;
      }
    }
    return valid;
  }

  public static void main(String[] args)
      throws ConverterException, IOException, URISyntaxException {
    UriReader reader = new UriReader();
    Converter converter = new JacksonConverter();
    DocumentLoader loader = new DocumentLoader(reader, converter);
    SchemaStore store = new SchemaStore(loader);
    URI schemaUri = new URI("file://" + args[0]);

    // Register the schema
    Long compileStart = System.nanoTime();
    store.register(schemaUri);
    JsonSchema schema = store.getSchema(schemaUri);
    ValidatorSettings settings = new ValidatorSettings();
    Validator validator = new Validator(settings);
    Long compileEnd = System.nanoTime();

    // Load all documents
    List<JsonInstance> docs =
        Files.readAllLines(Paths.get(args[1])).stream()
            .map(
                l -> {
                  try {
                    return new JsonInstance(converter.convert(l));
                  } catch (ConverterException e) {
                    throw new RuntimeException(e);
                  }
                })
            .collect(Collectors.toList());

    Long coldStart = System.nanoTime();
    boolean valid = validateAll(validator, schema, docs);
    Long coldEnd = System.nanoTime();

    if (!valid) {
      System.exit(1);
    }

    // Warmup
    long iterations = (long) Math.ceil(((double) MAX_WARMUP_TIME) / (coldEnd - coldStart));
    for (int i = 0; i < WARMUP_ITERATIONS; i++) {
      validateAll(validator, schema, docs);
    }

    Long warmStart = System.nanoTime();
    validateAll(validator, schema, docs);
    Long warmEnd = System.nanoTime();

    System.out.println(
        (coldEnd - coldStart) + "," + (warmEnd - warmStart) + "," + (compileEnd - compileStart));
  }
}
