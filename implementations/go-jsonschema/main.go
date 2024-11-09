package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"math"
	"os"
	"path/filepath"
	"time"

	"github.com/santhosh-tekuri/jsonschema/v6"
)

const WarmupIterations = 1000
const MaxWarmupTime = 10_000_000_000

func validateAll(instances []interface{}, sch *jsonschema.Schema) error {
	for _, inst := range instances {
		if err := sch.Validate(inst); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Please provide the example folder path as an argument")
	}

	exampleFolder := os.Args[1]

	// Construct and canonicalize file paths
	schemaFile, err := filepath.Abs(filepath.Join(exampleFolder, "schema.json"))
	if err != nil {
		log.Fatalf("Error constructing schema file path: %v", err)
	}

	instanceFile, err := filepath.Abs(filepath.Join(exampleFolder, "instances.jsonl"))
	if err != nil {
		log.Fatalf("Error constructing instance file path: %v", err)
	}

	// Compile the JSON schema
	c := jsonschema.NewCompiler()

	compile_start := time.Now()
	sch, err := c.Compile(schemaFile)
	compile_duration := time.Since(compile_start)

	if err != nil {
		log.Fatal(err)
	}

	// Open the JSONL file
	f, err := os.Open(instanceFile)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()

	// Decode and store JSON objects
	var instances []interface{}
	reader := bufio.NewReader(f)
	decoder := json.NewDecoder(reader)

	for {
		var inst interface{}
		if err := decoder.Decode(&inst); err != nil {
			if err == io.EOF {
				break
			}
			log.Fatalf("Error decoding JSON: %v", err)
		}
		instances = append(instances, inst)
	}

	// Cold start
	coldStart := time.Now()
	err = validateAll(instances, sch)
	if err != nil {
		log.Fatalf("Validation failed: %v", err)
	}
	coldDuration := time.Since(coldStart)

	// Warmup
	iterations := math.Ceil(float64(MaxWarmupTime) / float64(coldDuration.Nanoseconds()))
	for _ = range int64(min(iterations, WarmupIterations)) {
		validateAll(instances, sch)
	}

	warmStart := time.Now()
	validateAll(instances, sch)
	warmDuration := time.Since(warmStart)

	// Print timing
	fmt.Printf("%d,%d,%d\n", coldDuration.Nanoseconds(), warmDuration.Nanoseconds(), compile_duration.Nanoseconds())
}
