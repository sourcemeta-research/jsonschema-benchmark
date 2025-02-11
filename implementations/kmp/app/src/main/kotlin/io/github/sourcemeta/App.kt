package io.github.sourcemeta


import io.github.optimumcode.json.schema.OutputCollector
import io.github.optimumcode.json.schema.JsonSchema
import io.github.optimumcode.json.schema.ValidationError
import java.io.File
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement


val WARMUP_ITERATIONS: ULong = 1000.toULong()
val MAX_WARMUP_TIME: ULong = (1e9 * 10).toULong()


fun validateAll(schema: JsonSchema, docs: List<JsonElement>): Boolean {
  var valid = true
  for (doc in docs) {
    valid = valid && schema.validate(doc, OutputCollector.flag()).valid
  }
  return valid
}

fun main(args: Array<String>) {
    val json = Json { ignoreUnknownKeys = true }

    // Prepare the schema
    val schemaDefinition = File(args[0]).readText()
    val compileStart = System.nanoTime()
    val schema = JsonSchema.fromDefinition(schemaDefinition)
    val compileEnd = System.nanoTime()

    // Load all documents
    val docs = File(args[1]).readLines().map { json.parseToJsonElement(it) }

    val coldStart = System.nanoTime()
    val valid = validateAll(schema, docs)
    val coldEnd = System.nanoTime()

    if (!valid) {
        System.exit(1)
    }

    // Run some warmup iterations
    val iterations: ULong = kotlin.math.ceil(MAX_WARMUP_TIME.toDouble() / (coldEnd - coldStart)).toULong()
    repeat(kotlin.math.min(iterations, WARMUP_ITERATIONS).toInt()) {
        validateAll(schema, docs)
    }

    val warmStart = System.nanoTime()
    validateAll(schema, docs)
    val warmEnd = System.nanoTime()

    println("${coldEnd - coldStart},${warmEnd - warmStart},${compileEnd - compileStart}")
}
