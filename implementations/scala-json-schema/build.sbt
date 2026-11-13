name := "scala-json-schema-benchmark"
ThisBuild / version := "1.0"
ThisBuild / scalaVersion := "3.3.3"
resolvers += Resolver.mavenCentral

val jsonSchemaVersion = "0.4.0"
libraryDependencies += "io.github.jam01" %% "json-schema" % jsonSchemaVersion
// Not a transitive dependency of json-schema (see its README): the upickle-core version json-schema_3:0.4.0 uses.
libraryDependencies += "com.lihaoyi" %% "ujson" % "3.3.1"

assembly / assemblyJarName := "benchmark.jar"
assembly / mainClass := Some("Main")
assembly / assemblyMergeStrategy := {
  case PathList("META-INF", _*) => MergeStrategy.discard
  case _ => MergeStrategy.first
}
