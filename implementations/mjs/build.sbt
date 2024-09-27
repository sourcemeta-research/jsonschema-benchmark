name := "mjs-validator"

ThisBuild / version := "1.0"
ThisBuild / scalaVersion := "2.13.10"

javacOptions ++= Seq("-source", "17", "-target", "17")

resolvers += Resolver.mavenCentral

libraryDependencies ++= Seq(
  "org.scala-lang" % "scala-library" % "2.13.10"
)

val mjsVersion = "v0.1.0"
lazy val mjs = RootProject(
  uri(s"https://gitlab.lip6.fr/jsonschema/modernjsonschemavalidator.git#$mjsVersion")
)
lazy val benchmarkMjs = (project in file(".")).dependsOn(mjs)
assembly / assemblyJarName := "benchmarkMjs.jar"
assembly / packageOptions := Seq(
  Package.ManifestAttributes(
    "Main-Class" -> "Benchmark",
    "Implementation-Group" -> "org.up.mjs",
    "Implementation-Name" -> "mjs",
    "Implementation-Version" -> mjsVersion
  )
)

scalacOptions += "-Ymacro-annotations"
