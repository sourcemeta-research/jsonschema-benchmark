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

package std

import (
	"cmp"
	"slices"
)

func SortedKeys[A cmp.Ordered, B any](m map[A]B) []A {
	keys := make([]A, len(m))
	for k, _ := range m {
		keys = append(keys, k)
	}
	slices.Sort(keys)
	return keys
}
