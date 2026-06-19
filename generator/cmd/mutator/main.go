// Copyright 2026 Walter Schulze
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/katydid/validator-jsonschema-benchmarks/generator/rand"
	"github.com/katydid/validator-jsonschema-benchmarks/generator/rand/randjson"
	"github.com/katydid/validator-jsonschema-benchmarks/generator/std"
	jsonschema "github.com/santhosh-tekuri/jsonschema/v6"
)

func main() {
	log.SetFlags(log.Lshortfile)
	seed := flag.Int64("seed", time.Now().UnixNano(), "seed for random generator (defaults to now)")
	num := flag.Int("num", -1, "number of random json lines to generate (defaults to the number of items in the valid instances.jsonl)")
	flag.Parse()
	args := flag.Args()
	if len(args) == 0 {
		panic("expected folder to mutate")
	}
	srcfolder := args[0]
	dstfolder := srcfolder + "-invalid"
	if strings.Contains(srcfolder, "-valid") {
		dstfolder = strings.Replace(srcfolder, "-valid", "-invalid", 1)
	}
	fmt.Printf("mutating %s to %s with seed %d\n", srcfolder, dstfolder, *seed)
	r := rand.NewRandWithSeed(*seed)
	schemaBytes, err := os.ReadFile(filepath.Join(srcfolder, "schema.json"))
	if err != nil {
		panic(err)
	}
	schema, err := newValidator(string(schemaBytes))
	if err != nil {
		panic(err)
	}
	instancesBytes, err := os.ReadFile(filepath.Join(srcfolder, "instances.jsonl"))
	if err != nil {
		panic(err)
	}
	lines := bytes.Split(instancesBytes, []byte("\n"))
	lines = lines[:len(lines)-1]
	if (num == nil) || (*num == -1) {
		n := len(lines)
		num = &n
	}
	if err := os.Mkdir(dstfolder, 0755); err != nil {
		panic(err)
	}
	if err := os.WriteFile(filepath.Join(dstfolder, "schema.json"), schemaBytes, 0644); err != nil {
		panic(err)
	}
	newlines := []string{}
	i := 0
	for len(newlines) < (*num + 1) {
		line := lines[i%len(lines)]
		newline := mutate(r, schema, string(line))
		if newline == nil {
			log.Printf("mutation failed for %s", line)
		} else {
			newlines = append(newlines, *newline)
		}
		i++
	}
	newbytes := []byte(strings.Join(newlines, "\n"))
	if err := os.WriteFile(filepath.Join(dstfolder, "instances.jsonl"), newbytes, 0644); err != nil {
		panic(err)
	}
}

func mutate(r rand.Rand, v *jsonschema.Schema, line string) *string {
	attempts := 100
	for attempts > 0 {
		if res := tryFieldMutate(r, v, line); res != nil {
			return res
		}
		attempts--
	}
	return nil
}

func tryFieldMutate(r rand.Rand, v *jsonschema.Schema, line string) *string {
	m, err := std.UnmarshalToAnyWithJSONNumber([]byte(line))
	if err != nil {
		panic(err)
	}
	n := numMutationPoints(m)
	if n == 0 {
		return nil
	}
	p := r.Intn(n)
	m1 := mutatePoint(r, m, &p)
	data, err := json.Marshal(m1)
	if err != nil {
		panic(err)
	}
	data = bytes.Replace(data, []byte(`\u003e`), []byte(">"), -1)
	datas := string(data)
	return try(v, datas)
}

func mutatePoint(r rand.Rand, a any, p *int) any {
	switch t := a.(type) {
	case map[string]any:
		for _, k := range std.SortedKeys(t) {
			if *p == 0 {
				s, err := strconv.Unquote(randjson.String(r))
				if err != nil {
					panic(err)
				}
				k = s
			}
			*p = *p - 1
			v := t[k]
			v = mutatePoint(r, v, p)
			t[k] = v
		}
		return t
	case []any:
		for i, v := range t {
			v = mutatePoint(r, v, p)
			t[i] = v
			*p = *p - 1
		}
		return t
	default:
		if *p == 0 {
			// TODO: do not generate only ints when more implementations can support more variety
			// TODO: do not generate just ascii when more implementations can support more variety
			s := randjson.Value(r, randjson.WithMaxDepth(1), randjson.WithAscii(), randjson.OnlyInts())
			v, err := std.UnmarshalToAnyWithJSONNumber([]byte(s))
			if err != nil {
				panic(err)
			}
			return v
		}
		*p = *p - 1
	}
	return a
}

func numMutationPoints(a any) int {
	n := 0
	switch t := a.(type) {
	case map[string]any:
		for _, v := range t {
			n += 1
			n += numMutationPoints(v)
		}
	case []any:
		for _, v := range t {
			n += 1
			n += numMutationPoints(v)
		}
	default:
		n = 1
	}
	return n
}

func tryRuneMutate(r rand.Rand, v *jsonschema.Schema, line string) *string {
	runes := []rune(line)
	l := len(runes)
	if l == 0 {
		return nil
	}
	index := r.Intn(l)
	newrune := r.Intn(utf8.MaxRune)
	runes[index] = rune(newrune)
	res := string(runes)
	return try(v, res)
}

func try(v *jsonschema.Schema, res string) *string {
	valid, err := isValid(v, []byte(res))
	if err != nil {
		return nil
	}
	if valid {
		return nil
	}
	r := string(res)
	return &r
}

func newValidator(schemaJSON string) (*jsonschema.Schema, error) {
	c := jsonschema.NewCompiler()
	c.AssertFormat()
	doc, err := jsonschema.UnmarshalJSON(bytes.NewReader([]byte(schemaJSON)))
	if err != nil {
		return nil, err
	}
	if err := c.AddResource("schema.json", doc); err != nil {
		return nil, err
	}
	return c.Compile("schema.json")
}

func isValid(validator *jsonschema.Schema, jsonData []byte) (bool, error) {
	a, err := jsonschema.UnmarshalJSON(bytes.NewReader(jsonData))
	if err != nil {
		return false, err
	}
	return validator.Validate(a) == nil, nil
}
