# Copyright 2026 Walter Schulze
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

generate:
	go run ./cmd/generator -seed=123456 -num=10000 ../schemas/

clean_mutate:
	rm -rf ../schemas/ansible-meta-invalid || true
	rm -rf ../schemas/aws-cdk-invalid || true
	rm -rf ../schemas/babelrc-invalid || true
	rm -rf ../schemas/clang-format-invalid || true
	rm -rf ../schemas/cmake-presets-invalid || true
	rm -rf ../schemas/code-climate-invalid || true
	rm -rf ../schemas/cql2-invalid || true
	rm -rf ../schemas/cypress-invalid || true
	rm -rf ../schemas/deno-rmUniqueItems-invalid || true
	rm -rf ../schemas/dependabot-invalid || true
	rm -rf ../schemas/draft-04-rmUniqueItems-invalid || true
	rm -rf ../schemas/fabric-mod-invalid || true
	rm -rf ../schemas/geojson-invalid || true
	rm -rf ../schemas/gitpod-configuration-invalid || true
	rm -rf ../schemas/helm-chart-lock-invalid || true
	rm -rf ../schemas/importmap-invalid || true
	rm -rf ../schemas/jasmine-invalid || true
	rm -rf ../schemas/jsconfig-rmUniqueItems-invalid || true
	rm -rf ../schemas/jshintrc-invalid || true
	rm -rf ../schemas/lazygit-rmUniqueItems-invalid || true
	rm -rf ../schemas/lerna-invalid || true
	rm -rf ../schemas/nest-cli-invalid || true
	rm -rf ../schemas/omnisharp-invalid || true
	rm -rf ../schemas/openapi-invalid || true
	rm -rf ../schemas/pre-commit-hooks-invalid || true
	rm -rf ../schemas/pulumi-invalid || true
	rm -rf ../schemas/semantic-release-invalid || true
	rm -rf ../schemas/stale-invalid || true
	rm -rf ../schemas/stylecop-rmUniqueItems-invalid || true
	rm -rf ../schemas/tmuxinator-invalid || true
	rm -rf ../schemas/ui5-invalid || true
	rm -rf ../schemas/unreal-engine-uproject-rmUniqueItems-invalid || true
	rm -rf ../schemas/vercel-invalid || true
	rm -rf ../schemas/yamllint-invalid || true

# babelrc-invalid: blaze (https://github.com/sourcemeta/blaze/issues/874)
# draft-04-rmUniqueItems-invalid: limit generation to 500 instances to avoid issues with go-kaptinlin. TODO report issue and when it is fixed, undo the limit.
# jsconfig-rmUniqueItems-invalid: limit generation to 400 instances to avoid issues with networknt. TODO report issue and when it is fixed, undo the limit.
# vercel-invalid: change seed and limit generation to 500 instances to avoid issues with blaze. TODO report issue and when it is fixed, undo the limit.

# TODO fix clang-format-invalid: katydid
# TODO fix cmake-presets-invalid: katydid
# TODO investigate ui5-invalid: katydid, jsu-c, jsu-java, jsu-js, jsu-py

mutate:
	make clean_mutate
	go run ./cmd/mutator -seed=123456 ../schemas/ansible-meta
	go run ./cmd/mutator -seed=123456 ../schemas/aws-cdk
	go run ./cmd/mutator -seed=123456 ../schemas/babelrc
	go run ./cmd/mutator -seed=123456 ../schemas/clang-format 
	go run ./cmd/mutator -seed=123456 ../schemas/cmake-presets
	go run ./cmd/mutator -seed=123456 ../schemas/code-climate
	go run ./cmd/mutator -seed=123456 ../schemas/cypress
	go run ./cmd/mutator -seed=123456 ../schemas/deno-rmUniqueItems
	go run ./cmd/mutator -seed=123456 ../schemas/dependabot
	go run ./cmd/mutator -seed=123456 -num=500 ../schemas/draft-04-rmUniqueItems 
	go run ./cmd/mutator -seed=123456 ../schemas/fabric-mod 
	go run ./cmd/mutator -seed=123456 ../schemas/geojson
	go run ./cmd/mutator -seed=123456 ../schemas/gitpod-configuration
	go run ./cmd/mutator -seed=123456 ../schemas/importmap 
	go run ./cmd/mutator -seed=123456 ../schemas/jasmine 
	go run ./cmd/mutator -seed=123456 -num=400 ../schemas/jsconfig-rmUniqueItems 
	go run ./cmd/mutator -seed=123456 ../schemas/jshintrc
	go run ./cmd/mutator -seed=123456 ../schemas/lazygit-rmUniqueItems
	go run ./cmd/mutator -seed=123456 ../schemas/lerna
	go run ./cmd/mutator -seed=123456 ../schemas/nest-cli
	go run ./cmd/mutator -seed=123456 ../schemas/omnisharp 
	go run ./cmd/mutator -seed=123456 ../schemas/pre-commit-hooks
	go run ./cmd/mutator -seed=123456 ../schemas/pulumi 
	go run ./cmd/mutator -seed=123456 ../schemas/semantic-release
	go run ./cmd/mutator -seed=123456 ../schemas/stale 
	go run ./cmd/mutator -seed=123456 ../schemas/stylecop-rmUniqueItems
	go run ./cmd/mutator -seed=123456 ../schemas/tmuxinator
	go run ./cmd/mutator -seed=123456 ../schemas/ui5 
	go run ./cmd/mutator -seed=123456 ../schemas/unreal-engine-uproject-rmUniqueItems 
	go run ./cmd/mutator -seed=1 -num=500 ../schemas/vercel 
	go run ./cmd/mutator -seed=123456 ../schemas/yamllint