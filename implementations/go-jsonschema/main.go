package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"
	"strings"
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
	schemaFile, err := filepath.Abs(filepath.Join(exampleFolder, "schema-noformat.json"))
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

	// Read the JSONL file
	data, err := os.ReadFile(instanceFile)
	if err != nil {
		log.Fatal(err)
	}
	lines := strings.Split(string(data), "\n")

	// Decode and store JSON objects
	parseStart := time.Now()
	var instances []interface{}
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		var inst interface{}
		if err := json.Unmarshal([]byte(line), &inst); err != nil {
			log.Fatalf("Error decoding JSON: %v", err)
		}
		instances = append(instances, inst)
	}
	parseDuration := time.Since(parseStart)

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
	fmt.Printf("%d,%d,%d,%d\n", coldDuration.Nanoseconds(), warmDuration.Nanoseconds(), compile_duration.Nanoseconds(), parseDuration.Nanoseconds())
}
