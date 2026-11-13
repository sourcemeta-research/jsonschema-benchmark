name := "rc-circe-json-schema-benchmark"
ThisBuild / version := "1.0"
ThisBuild / scalaVersion := "3.3.1"
resolvers += Resolver.mavenCentral

val circeVersion = "0.14.6"
libraryDependencies ++= Seq("io.circe" %% "circe-core", "io.circe" %% "circe-parser").map(_ % circeVersion)
val rcCirceJsonVersion = "0.4.1"
libraryDependencies += "net.reactivecore" % "circe-json-schema_3" % rcCirceJsonVersion

assembly / assemblyJarName := "benchmark.jar"
assembly / mainClass := Some("Main")
assembly / assemblyMergeStrategy := {
  case PathList("META-INF", _*) => MergeStrategy.discard
  case _ => MergeStrategy.first
}
