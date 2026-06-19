package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	goreflect "reflect"
	"strings"
	"time"

	"github.com/katydid/parser-go-reflect/reflect"
	"github.com/katydid/validator-go-jsonschema/jsonschema"
)

const WarmupIterations = 1000
const MaxWarmupTime = 10_000_000_000

func validateAll(parser reflect.Parser, matcher jsonschema.Matcher, instances []goreflect.Value, want bool) error {
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

	// Open the JSONL file
	data, err := os.ReadFile(instanceFile)
	if err != nil {
		log.Fatal(err)
	}
	f := bytes.NewBuffer(data)
	reader := bufio.NewReader(f)

	// Decode and store JSON objects
	parsingStart := time.Now()
	var instances []goreflect.Value
	decoder := json.NewDecoder(reader)
	decoder.UseNumber()

	for {
		var inst any
		if err := decoder.Decode(&inst); err != nil {
			if err == io.EOF {
				break
			}
			log.Fatalf("Error decoding JSON: %v", err)
		}
		val := goreflect.ValueOf(inst)
		instances = append(instances, val)
	}
	parsingDuration := time.Since(parsingStart)
	parser := reflect.NewJSONSchemaParser()

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
	fmt.Printf("%d,%d,%d,%d\n", coldDuration.Nanoseconds(), warmDuration.Nanoseconds(), parsingDuration.Nanoseconds(), compile_duration.Nanoseconds())
}
