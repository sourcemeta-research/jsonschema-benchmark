package io.github.sourcemeta;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.networknt.schema.JsonSchema;
import com.networknt.schema.JsonSchemaFactory;
import com.networknt.schema.OutputFormat;
import com.networknt.schema.SchemaValidatorsConfig;
import com.networknt.schema.SpecVersion;
import com.networknt.schema.regex.GraalJSRegularExpressionFactory;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;

public class App {
  static int WARMUP_ITERATIONS = 1000;
  static long MAX_WARMUP_TIME = (long) 1e9 * 10;

  public static boolean validateAll(JsonSchema schema, List<JsonNode> docs) {
    boolean valid = true;
    for (JsonNode doc : docs) {
      valid = valid && schema.validate(doc, OutputFormat.BOOLEAN);
    }
    return valid;
  }

  public static void main(String[] args) throws IOException {
    JsonSchemaFactory jsonSchemaFactory =
        JsonSchemaFactory.getInstance(SpecVersion.VersionFlag.V202012);
    SchemaValidatorsConfig.Builder builder = SchemaValidatorsConfig.builder();
    builder.regularExpressionFactory(GraalJSRegularExpressionFactory.getInstance());
    SchemaValidatorsConfig config = builder.build();
    String schemaString = new String(Files.readAllBytes(Paths.get(args[0])));

    // Register the schema
    Long compileStart = System.nanoTime();
    JsonSchema schema = jsonSchemaFactory.getSchema(schemaString, config);
    Long compileEnd = System.nanoTime();

    // Load all documents
    ObjectMapper mapper = new ObjectMapper();
    List<JsonNode> docs =
        Files.readAllLines(Paths.get(args[1])).stream()
            .map(
                l -> {
                  try {
                    return mapper.readTree(l);
                  } catch (JsonProcessingException e) {
                    throw new RuntimeException(e);
                  }
                })
            .collect(Collectors.toList());

    Long coldStart = System.nanoTime();
    boolean valid = validateAll(schema, docs);
    Long coldEnd = System.nanoTime();

    if (!valid) {
      System.exit(1);
    }

    // Warmup
    long iterations = (long) Math.ceil(((double) MAX_WARMUP_TIME) / (coldEnd - coldStart));
    for (int i = 0; i < WARMUP_ITERATIONS; i++) {
      validateAll(schema, docs);
    }

    Long warmStart = System.nanoTime();
    validateAll(schema, docs);
    Long warmEnd = System.nanoTime();

    System.out.println(
        (coldEnd - coldStart) + "," + (warmEnd - warmStart) + "," + (compileEnd - compileStart));
  }
}
