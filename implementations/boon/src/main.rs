use std::{error::Error, fs::File, io::{BufReader, BufRead}, time::Instant};
use boon::{Compiler, Schemas};
use serde_json::Value;
use std::env;

fn main() -> Result<(), Box<dyn Error>> {
  let args: Vec<String> = env::args().collect();
  let example_folder = &args[1];
  let schema_file =   std::fs::canonicalize(example_folder.to_owned() + "/schema.json")?;
  let instance_file = std::fs::canonicalize(example_folder.to_owned() + "/instances.jsonl")?;

  let mut schemas = Schemas::new();
  let mut compiler = Compiler::new();
  let file = File::open(&instance_file)?;
  let reader = BufReader::new(file);
  let sch_index = compiler.compile(schema_file.to_str().ok_or("NULL")?, &mut schemas)?;

  let start = Instant::now();
  for line in reader.lines() {
      let line = line?;
      let instance: Value = serde_json::from_str(&line)?;

      // Validate each JSON object
      let result = schemas.validate(&instance, sch_index);
      assert!(result.is_ok(), "Validation failed for instance: {}", line);
  }

  let duration = start.elapsed().as_nanos();
  println!("{:?}", duration);

  Ok(())
}
