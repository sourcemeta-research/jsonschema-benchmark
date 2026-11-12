// The jsonschema-benchmark entry point for gojsonschema (draft 4, 6 and 7): read the instances into memory, parse
// each (timed), compile the schema (timed), validate every instance once cold, warm up, validate once more warm.
// Prints "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/xeipuuv/gojsonschema"
)

const warmupIterations = 100
const maxWarmupTime = 10_000_000_000

var drafts = map[string]gojsonschema.Draft{
	"http://json-schema.org/draft-07/schema": gojsonschema.Draft7,
	"http://json-schema.org/draft-06/schema": gojsonschema.Draft6,
	"http://json-schema.org/draft-04/schema": gojsonschema.Draft4,
}

func validateAll(schema *gojsonschema.Schema, instances []interface{}, report bool) bool {
	valid := true
	for i, instance := range instances {
		result, err := schema.Validate(gojsonschema.NewGoLoader(instance))
		if err != nil || !result.Valid() {
			if report {
				fmt.Fprintf(os.Stderr, "Error validating instance %d\n", i)
			}
			valid = false
		}
	}
	return valid
}

func fail(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, format+"\n", args...)
	os.Exit(1)
}

func main() {
	if len(os.Args) != 3 {
		fail("Usage: %s <schema.json> <instances.jsonl>", os.Args[0])
	}
	schemaBytes, err := os.ReadFile(os.Args[1])
	if err != nil {
		fail("Error reading the schema: %v", err)
	}
	data, err := os.ReadFile(os.Args[2])
	if err != nil {
		fail("Error reading the instances: %v", err)
	}
	var lines [][]byte
	for _, line := range bytes.Split(data, []byte("\n")) {
		if len(bytes.TrimSpace(line)) > 0 {
			lines = append(lines, line)
		}
	}

	parseStart := time.Now()
	instances := make([]interface{}, len(lines))
	for i, line := range lines {
		if err := json.Unmarshal(line, &instances[i]); err != nil {
			fail("Error parsing instance %d: %v", i, err)
		}
	}
	parseDuration := time.Since(parseStart)

	var schemaValue map[string]interface{}
	if err := json.Unmarshal(schemaBytes, &schemaValue); err != nil {
		fail("Error parsing the schema: %v", err)
	}

	compileStart := time.Now()
	loader := gojsonschema.NewSchemaLoader()
	if dialect, ok := schemaValue["$schema"].(string); ok {
		if draft, known := drafts[strings.TrimSuffix(dialect, "#")]; known {
			loader.Draft = draft
			loader.AutoDetect = false
		}
	}
	schema, err := loader.Compile(gojsonschema.NewGoLoader(schemaValue))
	compileDuration := time.Since(compileStart)
	if err != nil {
		fail("Error compiling the schema: %v", err)
	}

	coldStart := time.Now()
	valid := validateAll(schema, instances, true)
	coldDuration := time.Since(coldStart)

	iterations := (maxWarmupTime-1)/max(coldDuration.Nanoseconds(), 1) + 1
	for i := int64(0); i < min(iterations, warmupIterations); i++ {
		validateAll(schema, instances, false)
	}

	warmStart := time.Now()
	validateAll(schema, instances, false)
	warmDuration := time.Since(warmStart)

	fmt.Printf("%d,%d,%d,%d\n", coldDuration.Nanoseconds(), warmDuration.Nanoseconds(), compileDuration.Nanoseconds(), parseDuration.Nanoseconds())
	if !valid {
		os.Exit(1)
	}
}
