import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}
import io.circe.Json
import io.circe.parser.parse
import net.reactivecore.cjs.{DocumentValidator, Loader, ResolveFailure, Result}
import net.reactivecore.cjs.resolver.Downloader

// The jsonschema-benchmark entry point for rc-circe-json-schema (2020-12): read the instances into memory, parse each
// into circe's Json (timed), compile the schema (timed), validate every instance once cold, warm up, validate once more
// warm. Prints "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
object Main {
  // Nothing is fetched: a reference to another document fails to resolve.
  object NoDownloads extends Downloader[Result] {
    override def loadJson(url: String): Result[Json] = Left(ResolveFailure(s"Not fetching $url"))
  }

  def parseInstance(line: String): Json = parse(line).fold(throw _, identity)

  def compile(schemaText: String): DocumentValidator =
    Loader(NoDownloads).fromJson(parse(schemaText).fold(throw _, identity)).fold(e => throw new RuntimeException(e.toString), identity)

  def isValid(validator: DocumentValidator, instance: Json): Boolean = validator.validate(instance).isSuccess

  val WarmupIterations = 100L
  val MaxWarmupTime = 10000000000L

  def validateAll(validator: DocumentValidator, instances: Array[Json], report: Boolean): Boolean = {
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
