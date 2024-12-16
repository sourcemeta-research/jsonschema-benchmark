import main.MainClass

import scala.io.Source

object Benchmark {
  val WARMUP_ITERATIONS = 1000
  val MAX_WARMUP_TIME = 1e9 * 10

  def validateAll(schema: String, instance: String, registryMap: Map[String, String], instances: List[String]): Boolean = {
    var result = true
    for (instance <- instances) {
      result = result && MainClass.validateInstance(schema, instance, registryMap)
    }
    return result
  }

  def main(args: Array[String]): Unit = {
    if (args.length != 2) {
      System.exit(1)
    }
    val schemaPath = args(0)
    val instancePath = args(1)

    val compileStart = System.nanoTime()
    val schema = Source.fromFile(schemaPath).mkString
    val registryMap = Map.empty[String, String]
    val compileEnd = System.nanoTime()

    val instances = Source.fromFile(instancePath).getLines().toList

    val coldStart = System.nanoTime()
    var result = validateAll(schema, instancePath, registryMap, instances)
    val coldEnd = System.nanoTime()

    if (!result) {
      System.err.println("Invalid instance")
      System.exit(1)
    }

    val iterations = (MAX_WARMUP_TIME / (coldEnd - coldStart)).ceil.toInt
    (1 to iterations.min(WARMUP_ITERATIONS)).foreach(_ => {
      validateAll(schema, instancePath, registryMap, instances)
    })

    val warmStart = System.nanoTime()
    validateAll(schema, instancePath, registryMap, instances)
    val warmEnd = System.nanoTime()

    println((coldEnd - coldStart).toString + "," + (compileEnd - compileStart).toString)
  }
}
