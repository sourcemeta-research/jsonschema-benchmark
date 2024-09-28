import main.MainClass

import scala.io.Source

object Benchmark {
  def main(args: Array[String]): Unit = {
    if (args.length != 2) {
      System.exit(1)
    }
    val schemaPath = args(0)
    val instancePath = args(1)

    val schema = Source.fromFile(schemaPath).mkString
    val registryMap = Map.empty[String, String]

    val start = System.nanoTime()
    for (instance <- Source.fromFile(instancePath).getLines()) {
      val result = MainClass.validateInstance(schema, instance, registryMap)
      if (!result) {
        System.err.println("Invalid instance")
        System.exit(1)
      }
    }
    val finish = System.nanoTime()

    println((finish - start).toString)
  }
}
