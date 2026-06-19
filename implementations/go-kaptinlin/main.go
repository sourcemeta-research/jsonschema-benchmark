package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"os"
	"path/filepath"
	"strings"
	"time"

	jsonschema "github.com/kaptinlin/jsonschema"
)

// Does not support: "dependencies"

const WarmupIterations = 1000
const MaxWarmupTime = 10_000_000_000

func validateAll(instances []any, sch *jsonschema.Schema, want bool) error {
	var result error
	for i := range instances {
		err := sch.Validate(instances[i])
		if want && !err.IsValid() {
			result = err
		} else if !want && err.IsValid() {
			result = fmt.Errorf("expected invalid, but got valid at line %d", i+1)
		}
	}
	return result
}

func main() {
	log.SetFlags(log.Lshortfile)
	if len(os.Args) < 2 {
		log.Fatal("Please provide the example folder path as an argument")
	}

	exampleFolder := os.Args[1]
	want := !strings.Contains(exampleFolder, "-invalid")
	log.Printf("folder %q with base %s expect %v", exampleFolder, filepath.Base(exampleFolder), want)

	// Construct and canonicalize file paths
	schemaFile, err := filepath.Abs(filepath.Join(exampleFolder, "schema.json"))
	if err != nil {
		log.Fatalf("Error constructing schema file path: %v", err)
	}
	schemaData, err := os.ReadFile(schemaFile)
	if err != nil {
		log.Fatalf("Error reading schema data: %v", err)
	}

	instanceFile, err := filepath.Abs(filepath.Join(exampleFolder, "instances.jsonl"))
	if err != nil {
		log.Fatalf("Error constructing instance file path: %v", err)
	}

	// Compile the JSON schema
	compile_start := time.Now()

	compiler := jsonschema.NewCompiler()
	compiler.AssertFormat = true
	validator, err := compiler.Compile(schemaData)
	if err != nil {
		log.Fatalf("Error creating new validator: %v", err)
	}

	compile_duration := time.Since(compile_start)

	if err != nil {
		log.Fatal(err)
	}

	data, err := os.ReadFile(instanceFile)
	if err != nil {
		log.Fatal(err)
	}
	lines := bytes.Split(data, []byte("\n"))
	lines = lines[:len(lines)-1]
	log.Printf("number of instances: %d", len(lines))

	// Decode and store JSON objects
	parsingStart := time.Now()
	instances := make([]any, 0, len(lines))
	for i := range lines {
		var instance any
		if err := json.Unmarshal(lines[i], &instance); err != nil {
			log.Fatalf("Error unmarshaling instance: %v", err)
		}
		instances = append(instances, instance)
	}
	parsingDuration := time.Since(parsingStart)

	// Cold start
	coldStart := time.Now()
	err = validateAll(instances, validator, want)
	if err != nil {
		log.Fatalf("Validation failed: %v", err)
	}
	coldDuration := time.Since(coldStart)

	// Warmup
	iterations := math.Ceil(float64(MaxWarmupTime) / float64(coldDuration.Nanoseconds()))
	for _ = range int64(min(iterations, WarmupIterations)) {
		validateAll(instances, validator, want)
	}

	warmStart := time.Now()
	validateAll(instances, validator, want)
	warmDuration := time.Since(warmStart)

	// Print timing
	fmt.Printf("%d,%d,%d,%d\n", coldDuration.Nanoseconds(), warmDuration.Nanoseconds(), parsingDuration.Nanoseconds(), compile_duration.Nanoseconds())
}

func unmarshalToAny(data []byte) (any, error) {
	if len(data) == 0 {
		return nil, nil
	}
	var v any
	return v, json.Unmarshal(data, &v)
}
