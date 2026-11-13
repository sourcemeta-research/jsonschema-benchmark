import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}
import io.github.jam01.json_schema.{Config, Dialect, MutableRegistry, Uri}
import io.github.jam01.json_schema as js

// The jsonschema-benchmark entry point for jam01's json-schema (2020-12): read the instances into memory, compile the
// schema (timed), validate every instance once cold, warm up, validate once more warm. Prints
// "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
//
// The library validates as it reads JSON (its validator is a ujson visitor), and its in-memory ujson.Value rounds
// large numbers, so instances are validated from their text, as Bowtie's harness does: the cold and warm figures
// include parsing, and the parse figure is only taking a copy of each line.
object Main {
  type Compiled = upickle.core.Visitor[?, ?]

  val Metaschemas = Seq("schema", "meta/core", "meta/applicator", "meta/unevaluated", "meta/validation",
    "meta/meta-data", "meta/format-annotation", "meta/content")

  def parseInstance(line: String): String = new String(line.toCharArray)

  def compile(schemaText: String): Compiled = {
    val registry = new MutableRegistry
    Metaschemas.foreach { name =>
      val text = new String(getClass.getResourceAsStream(s"/metaschemas/${name.replace('/', '_')}.json").readAllBytes(),
        StandardCharsets.UTF_8)
      js.from(ujson.Readable, ujson.Readable.fromString(text),
        docbase = Uri(s"https://json-schema.org/draft/2020-12/$name"), registry = registry)
    }
    val schema = js.from(ujson.Readable, ujson.Readable.fromString(schemaText), registry = registry)
    js.validator(schema, Config(dialect = Dialect.FullSpec, ffast = true, resolveDialect = true), registry)
  }

  def isValid(validator: Compiled, instance: String): Boolean =
    ujson.Readable.transform(ujson.Readable.fromString(instance), validator).asInstanceOf[js.OutputUnit].vvalid

  val WarmupIterations = 100L
  val MaxWarmupTime = 10000000000L

  def validateAll(validator: Compiled, instances: Array[String], report: Boolean): Boolean = {
    var valid = true
    var i = 0
    while (i < instances.length) {
      if (!isValid(validator, instances(i))) {
        if (report) System.err.println(s"Error validating instance $i")
        valid = false
      }
      i += 1
    }
    valid
  }

  def main(args: Array[String]): Unit = {
    if (args.length != 2) {
      System.err.println("Usage: Main <schema.json> <instances.jsonl>")
      sys.exit(1)
    }
    val schemaText = new String(Files.readAllBytes(Paths.get(args(0))), StandardCharsets.UTF_8)
    val lines = new String(Files.readAllBytes(Paths.get(args(1))), StandardCharsets.UTF_8)
      .split("\n").filter(_.trim.nonEmpty)

    val parseStart = System.nanoTime()
    val instances = lines.map(parseInstance)
    val parse = System.nanoTime() - parseStart

    val compileStart = System.nanoTime()
    val validator = compile(schemaText)
    val compileTime = System.nanoTime() - compileStart

    val coldStart = System.nanoTime()
    val valid = validateAll(validator, instances, true)
    val cold = System.nanoTime() - coldStart

    val iterations = (MaxWarmupTime + math.max(cold, 1L) - 1) / math.max(cold, 1L)
    var w = 0L
    while (w < math.min(iterations, WarmupIterations)) {
      validateAll(validator, instances, false)
      w += 1
    }

    val warmStart = System.nanoTime()
    validateAll(validator, instances, false)
    val warm = System.nanoTime() - warmStart

    println(s"$cold,$warm,$compileTime,$parse")
    sys.exit(if (valid) 0 else 1)
  }
}
