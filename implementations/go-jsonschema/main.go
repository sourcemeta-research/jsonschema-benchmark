package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"
	"encoding/json"
	"io"

	"github.com/santhosh-tekuri/jsonschema/v6"
)

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
	sch, err := c.Compile(schemaFile)
	if err != nil {
		log.Fatal(err)
	}

	// Open the JSONL file
	f, err := os.Open(instanceFile)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()


	// Step 1: Decode and store JSON objects
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

	start := time.Now()

	// Step 2: Validation loop
	for _, inst := range instances {
		err = sch.Validate(inst)
		if err != nil {
			log.Fatalf("Validation failed: %v", err)
		}
	}

	// Stop timer and calculate duration
	duration := time.Since(start)

	// Print timing
	fmt.Printf("%v\n", duration)
}
