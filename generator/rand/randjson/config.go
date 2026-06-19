//  Copyright 2025 Walter Schulze
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

package randjson

type config struct {
	// maxDepth is the maximum number of objects/arrays to generate down. It makes sure the algorithm terminates.
	maxDepth        int
	maxObjectFields int
	maxArrayLength  int
	minStringLength int
	maxStringLength int
	noNewlines      bool // makes jsonl format possible, where newlines separate json objects.
	numberEdgeCases []string
	// r.Intn(c.numberEdgeCaseOdds) == 0 will result in a random edge case being generated.
	numberEdgeCaseOdds int
	maxSpaces          int

	notArray  bool
	notObject bool
	notBool   bool
	notString bool
	notNumber bool

	easyFloats  bool // only generate float64s
	easyStrings bool // only generate ascii strings
	onlyInts    bool // only generate ints, no floats
}

type Option func(*config)

func newConfig(opts ...Option) *config {
	// default Config
	c := &config{
		maxDepth:           5,
		maxObjectFields:    10,
		maxArrayLength:     10,
		maxStringLength:    100,
		numberEdgeCases:    defaultNumberEdgeCases,
		numberEdgeCaseOdds: 100,
		maxSpaces:          5,
		easyStrings:        true, // TODO make this false, but currently lots of engines struggle with unicode
		noNewlines:         true, // This is to support jsonl format and implementations being able to naively split .jsonl files on newline.
		easyFloats:         true, // TODO make these false by default. This is currently true since not all engines support large numbers. For example blaze struggles with `{"extendedAddress":"4Bj","region":"7qc0B1","postOfficeBox":"T1Q7C4","streetAddress":"6\udD74H38tHlS","countryName":"3","locality":"B"}`.
		onlyInts:           false,
	}
	// apply options
	for _, o := range opts {
		o(c)
	}
	return c
}

var defaultNumberEdgeCases = []string{
	"-0",
	"9223372036854775807",  // math.MaxInt64
	"9223372036854775808",  // math.MaxInt64 + 1
	"-9223372036854775808", // math.MinInt64
	"-9223372036854775809", // math.MinInt64 - 1
	"18446744073709551615", // math.MaxUint64
	"18446744073709551616", // math.MaxUint64 + 1
	"1.79769313486231570814527423731704356798070e+308",   // math.MaxFloat64
	"2.79769313486231570814527423731704356798070e+308",   // > math.MaxFloat64
	"4.9406564584124654417656879286822137236505980e-324", // math.SmallestNonzeroFloat64
}

func WithMaxDepth(maxDepth int) Option {
	return func(c *config) {
		c.maxDepth = maxDepth
	}
}

func WithMaxObjectFields(maxObjectFields int) Option {
	return func(c *config) {
		c.maxObjectFields = maxObjectFields
	}
}

func WithMaxArrayLength(maxArrayLength int) Option {
	return func(c *config) {
		c.maxArrayLength = maxArrayLength
	}
}

func WithMinStringLength(minStringLength int) Option {
	return func(c *config) {
		c.minStringLength = minStringLength
	}
}

func WithMaxStringLength(maxStringLength int) Option {
	return func(c *config) {
		c.maxStringLength = maxStringLength
	}
}

// WithMaxSpaces sets the maximum number of spaces generated at each opportunity to generate spaces.
func WithMaxSpaces(maxSpaces int) Option {
	return func(c *config) {
		c.maxSpaces = maxSpaces
	}
}

func NotArray() Option {
	return func(c *config) {
		c.notArray = true
	}
}

func NotObject() Option {
	return func(c *config) {
		c.notObject = true
	}
}

func NotBool() Option {
	return func(c *config) {
		c.notBool = true
	}
}

func NotString() Option {
	return func(c *config) {
		c.notString = true
	}
}

func NotNumber() Option {
	return func(c *config) {
		c.notNumber = true
	}
}

func WithAscii() Option {
	return func(c *config) {
		c.easyStrings = true
	}
}

func OnlyInts() Option {
	return func(c *config) {
		c.onlyInts = true
	}
}

// top level is not an the specific value, but we can generate those types below that.
func (c *config) resetNot() {
	c.notArray = false
	c.notObject = false
	c.notBool = false
	c.notString = false
	c.notNumber = false
}

func NoNewLines() Option {
	return func(c *config) {
		c.noNewlines = true
	}
}
