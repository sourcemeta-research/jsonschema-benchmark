name := "mjs-benchmark"
ThisBuild / version := "1.0"
ThisBuild / scalaVersion := "2.13.10"
resolvers += Resolver.mavenCentral

val circeVersion = "0.14.1"
libraryDependencies ++= Seq("io.circe" %% "circe-core", "io.circe" %% "circe-parser").map(_ % circeVersion)
val mjsVersion = "v0.1.0"
lazy val mjs = RootProject(uri(s"https://gitlab.lip6.fr/jsonschema/modernjsonschemavalidator.git#$mjsVersion"))
lazy val benchmark = (project in file(".")).dependsOn(mjs)

assembly / assemblyJarName := "benchmark.jar"
assembly / mainClass := Some("Main")
assembly / assemblyMergeStrategy := {
  case PathList("META-INF", _*) => MergeStrategy.discard
  case _ => MergeStrategy.first
}
