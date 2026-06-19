package main

import (
	"bytes"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/katydid/parser-go-json/json"
	"github.com/katydid/validator-go-jsonschema/jsonschema"
)

const WarmupIterations = 1000
const MaxWarmupTime = 10_000_000_000

func validateAll(parser json.Parser, matcher jsonschema.Matcher, instances [][]byte, want bool) error {
	for i := range instances {
		parser.Init(instances[i])
		got, err := matcher.MatchParser(parser)
		if err != nil {
			return err
		}
		if got != want {
			return fmt.Errorf("want %v, but got %v for instance: %s", want, got, instances[i])
		}
	}
	return nil
}

func main() {
	log.SetFlags(log.Lshortfile)
	if len(os.Args) < 2 {
		log.Fatal("Please provide the example folder path as an argument")
	}

	exampleFolder := os.Args[1]
	log.Printf("starting: %s", exampleFolder)
	want := !strings.Contains(exampleFolder, "-invalid")

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
	matcher, err := jsonschema.Compile([]byte(schemaData))
	compile_duration := time.Since(compile_start)
	log.Printf("compile duration: %v", compile_duration)
	if err != nil {
		log.Fatal(err)
	}

	// Read instances
	data, err := os.ReadFile(instanceFile)
	if err != nil {
		log.Fatal(err)
	}
	instances := bytes.Split(data, []byte("\n"))
	instances = instances[:len(instances)-1]
	log.Printf("number of instances: %d", len(instances))

	parser := json.NewJSONSchemaParser()

	// Cold start
	coldStart := time.Now()
	err = validateAll(parser, matcher, instances, want)
	if err != nil {
		log.Fatalf("Validation failed: %v", err)
	}
	coldDuration := time.Since(coldStart)

	// Nothing to warmup in compiled version
	// iterations := math.Ceil(float64(MaxWarmupTime) / float64(coldDuration.Nanoseconds()))
	// for _ = range int64(min(iterations, WarmupIterations)) {
	// 	validateAll(parser, matcher, instances, want)
	// }

	warmStart := time.Now()
	validateAll(parser, matcher, instances, want)
	warmDuration := time.Since(warmStart)

	// Print timing
	fmt.Printf("%d,%d,0,%d\n", coldDuration.Nanoseconds(), warmDuration.Nanoseconds(), compile_duration.Nanoseconds())
}
