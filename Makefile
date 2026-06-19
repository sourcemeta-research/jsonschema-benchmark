.DEFAULT_GOAL := all
# Rather than `SCHEMAS = $(notdir $(wildcard schemas/*))`, we create a curated list of schemas:
SCHEMAS = $(shell cat curated_schemas.txt)
ALL_IMPLEMENTATIONS = $(notdir $(wildcard implementations/*))
ifeq ($(NO_IGNORE),yes)
IMPLEMENTATIONS ?= $(ALL_IMPLEMENTATIONS)
else
IMPLEMENTATIONS ?= $(filter-out $(patsubst implementations/%/,%,$(dir $(wildcard implementations/*/.benchmark-ignore))), $(ALL_IMPLEMENTATIONS))
endif
RUNS := 1

.PHONY: clean
clean: ; rm -rf dist implementations/*/.dockertimestamp
dist: ; mkdir $@
dist/results: | dist ; mkdir $@
dist/temp: | dist ; mkdir $@
define PREPARE_IMPLEMENTATION
dist/results/$1: | dist/results ; mkdir $$@
dist/temp/$1: | dist/temp ; mkdir $$@
ALL_TARGETS += $$(addprefix dist/results/$1/,$(SCHEMAS))
endef
ALL_INSTANCES := $(foreach schema,$(SCHEMAS),schemas/$(schema)/instances.jsonl)
$(foreach implementation,$(IMPLEMENTATIONS),$(eval $(call PREPARE_IMPLEMENTATION,$(implementation))))
dist/report.csv: report.sh $(ALL_TARGETS) | dist ; ./$< $(ALL_TARGETS) > $@

.PHONY: all
all: dist/report.csv ; cat $<

define docker_run
  $(eval $@_TOOL = $(1))
  $(eval $@_INPUT = $(2))
  $(eval $@_MISC = $(3))
	rm -f $@
	for i in $(shell seq 1 $(RUNS)) ; do \
		timeout -s KILL $$(( $(RUNS) * 180 + 60 ))s \
			docker run --rm -v $(CURDIR):/workspace \
				jsonschema-benchmark/$($@_TOOL) $($@_INPUT) $($@_MISC) > $@.tmp ; \
		STATUS=$$? ; \
		if ! grep '.*,.*,' $@.tmp > /dev/null; then printf "0,0,0,0," >> $@ ; cat $@.tmp  >> $@ ; else cat $@.tmp >> $@ ; fi ; \
		sed "$$ s/$$/,$$STATUS/" $@ > $@.tmp ; mv $@.tmp $@ ; \
		rm -f $@.tmp ; \
	done
endef

.PHONY: list_schemas
list_schemas:
	@echo ${SCHEMAS}

list:
	@echo $(IMPLEMENTATIONS) | tr ' ' '\n'

implementations/%/memory-wrapper.sh: memory-wrapper.sh
	cp -p $< $@

generate:
	(cd generator && make generate)

mutate:
	(cd generator && make mutate)

analytics-schemas-latex:
	(cd analytics/cmd/schemas && go run main.go --format=latex --latex.pifont --rmUniqueItems --rmSource --groupGen ../../../schemas > ../../../schemas.tex)

analytics-schemas-md:
	(cd analytics/cmd/schemas && go run main.go --format=md ../../../schemas > ../../../schemas.md)

analytics-results-latex:
	(cd analytics/cmd/result && go run main.go \
	  --format=latex \
	  --latex.pifont \
	  --rmUniqueItems \
	  --shortSchemaName \
	  --filterSchema1 \
	  --schemasFolder=../../../schemas \
	  ../../../dist/report.csv \
	  > ../../../results.tex)

analytics-results-md:
	(cd analytics/cmd/result && go run main.go \
	  --format=md \
	  --rmUniqueItems \
	  --shortSchemaName \
	  --filterSchema1 \
	  --schemasFolder=../../../schemas \
	  ../../../dist/report.csv \
	  > ../../../results.md)

analytics-impls-md:
	(cd analytics/cmd/impls && go run main.go \
	  --format=md \
	  --filterSchema1 \
	  --schemasFolder=../../../schemas \
	  ../../../dist/report.csv \
	  > ../../../impls.md)

analytics-impls-latex:
	(cd analytics/cmd/impls && go run main.go \
	  --format=latex \
	  --filterSchema1 \
	  --schemasFolder=../../../schemas \
	  ../../../dist/report.csv \
	  > ../../../impls.tex)

run:
	make dist/report.csv

# Blaze

implementations/blaze/.dockertimestamp: \
	implementations/blaze/memory-wrapper.sh \
	implementations/blaze/CMakeLists.txt \
	implementations/blaze/main.cc \
	implementations/blaze/Dockerfile
	docker build -t jsonschema-benchmark/blaze implementations/blaze
	touch $@

dist/results/blaze/%: \
	implementations/blaze/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/blaze
	@$(call docker_run,blaze,/workspace/$(dir $(word 2,$^)))

# Rapidjson

implementations/rapidjson/.dockertimestamp: \
	implementations/rapidjson/memory-wrapper.sh \
	implementations/rapidjson/CMakeLists.txt \
	implementations/rapidjson/main.cc \
	implementations/rapidjson/Dockerfile
	docker build -t jsonschema-benchmark/rapidjson implementations/rapidjson
	touch $@

dist/results/rapidjson/%: \
	implementations/rapidjson/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/rapidjson
	@$(call docker_run,rapidjson,/workspace/$(dir $(word 2,$^)))

# AJV

implementations/ajv/.dockertimestamp: \
	implementations/ajv/memory-wrapper.sh \
	implementations/ajv/main.mjs \
	implementations/ajv/package.json \
	implementations/ajv/Dockerfile
	docker build -t jsonschema-benchmark/ajv implementations/ajv
	touch $@

dist/results/ajv/%: \
	implementations/ajv/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/ajv
	@$(call docker_run,ajv,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# AJV with bun

implementations/ajv-bun/.dockertimestamp: \
	implementations/ajv-bun/memory-wrapper.sh \
	implementations/ajv/main.mjs \
	implementations/ajv-bun/package.json \
	implementations/ajv-bun/Dockerfile
	cp implementations/ajv/main.mjs implementations/ajv-bun
	docker build -t jsonschema-benchmark/ajv-bun implementations/ajv-bun
	touch $@

dist/results/ajv-bun/%: \
	implementations/ajv-bun/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/ajv-bun
	@$(call docker_run,ajv-bun,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# BOON

implementations/boon/.dockertimestamp: \
	implementations/boon/memory-wrapper.sh \
	implementations/boon/src/main.rs \
	implementations/boon/Cargo.toml \
	implementations/boon/Dockerfile
	docker build -t jsonschema-benchmark/boon implementations/boon
	touch $@

dist/results/boon/%: \
	implementations/boon/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/boon
	@$(call docker_run,boon,/workspace/$(dir $(word 2,$^)))

# JSU - JSON Schema Utils Compiler with JMC Backend for C, JS, Python, Perl, Java

implementations/jsu-c/.dockertimestamp: \
	implementations/jsu-c/memory-wrapper.sh \
	implementations/jsu-c/benchmark.sh \
	implementations/jsu-c/jsonschema_benchmark.c \
	implementations/jsu-c/version.sh \
	implementations/jsu-c/Dockerfile
	docker build -t jsonschema-benchmark/jsu-c implementations/jsu-c
	touch $@

dist/results/jsu-c/%: \
	implementations/jsu-c/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsu-c
	@$(call docker_run,jsu-c,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

implementations/jsu-js/.dockertimestamp: \
	implementations/jsu-js/memory-wrapper.sh \
	implementations/jsu-js/benchmark.sh \
	implementations/jsu-js/jsonschema_benchmark.js \
	implementations/jsu-js/version.sh \
	implementations/jsu-js/Dockerfile
	docker build -t jsonschema-benchmark/jsu-js implementations/jsu-js
	touch $@

dist/results/jsu-js/%: \
	implementations/jsu-js/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsu-js
	@$(call docker_run,jsu-js,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

implementations/jsu-py/.dockertimestamp: \
	implementations/jsu-py/memory-wrapper.sh \
	implementations/jsu-py/benchmark.sh \
	implementations/jsu-py/jsonschema_benchmark.py \
	implementations/jsu-py/version.sh \
	implementations/jsu-py/Dockerfile
	docker build -t jsonschema-benchmark/jsu-py implementations/jsu-py
	touch $@

dist/results/jsu-py/%: \
	implementations/jsu-py/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsu-py
	@$(call docker_run,jsu-py,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

implementations/jsu-pl/.dockertimestamp: \
	implementations/jsu-pl/memory-wrapper.sh \
	implementations/jsu-pl/benchmark.sh \
	implementations/jsu-pl/jsonschema_benchmark.pl \
	implementations/jsu-pl/version.sh \
	implementations/jsu-pl/Dockerfile
	docker build -t jsonschema-benchmark/jsu-pl implementations/jsu-pl
	touch $@

dist/results/jsu-pl/%: \
	implementations/jsu-pl/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsu-pl
	@$(call docker_run,jsu-pl,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

implementations/jsu-java/.dockertimestamp: \
	implementations/jsu-java/memory-wrapper.sh \
	implementations/jsu-java/benchmark.sh \
	implementations/jsu-java/JsonSchemaBenchmark.java \
	implementations/jsu-java/version.sh \
	implementations/jsu-java/Dockerfile
	docker build -t jsonschema-benchmark/jsu-java implementations/jsu-java
	touch $@

dist/results/jsu-java/%: \
	implementations/jsu-java/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsu-java
	@$(call docker_run,jsu-java,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# JSON_SCHEMER

implementations/json_schemer/.dockertimestamp: \
	implementations/json_schemer/memory-wrapper.sh \
	implementations/json_schemer/main.rb \
	implementations/json_schemer/Gemfile \
	implementations/json_schemer/Gemfile.lock \
	implementations/json_schemer/Dockerfile
	docker build -t jsonschema-benchmark/json_schemer implementations/json_schemer
	touch $@

dist/results/json_schemer/%: \
	implementations/json_schemer/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/json_schemer
	@$(call docker_run,json_schemer,/workspace/$(dir $(word 3,$^)))

# PYTHON / JSONSCHEMA

implementations/py-jsonschema/.dockertimestamp: \
	implementations/py-jsonschema/memory-wrapper.sh \
	implementations/py-jsonschema/validate.py \
	implementations/py-jsonschema/pyproject.toml \
	implementations/py-jsonschema/Dockerfile
	docker build -t jsonschema-benchmark/py-jsonschema implementations/py-jsonschema
	touch $@

dist/results/py-jsonschema/%: \
	implementations/py-jsonschema/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/py-jsonschema
	@$(call docker_run,py-jsonschema,/workspace/$(dir $(word 2,$^)))

# GO / GOOGLE

implementations/go-google/.dockertimestamp: \
	implementations/go-google/memory-wrapper.sh \
	implementations/go-google/go.mod \
	implementations/go-google/go.sum \
	implementations/go-google/main.go \
	implementations/go-google/Dockerfile
	docker build -t jsonschema-benchmark/go-google implementations/go-google
	touch $@

dist/results/go-google/%: \
	implementations/go-google/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-google
	@$(call docker_run,go-google,/workspace/$(dir $(word 2,$^)))

# GO / JSON_SCHEMA_SPEC

implementations/go-json-schema-spec/.dockertimestamp: \
	implementations/go-json-schema-spec/memory-wrapper.sh \
	implementations/go-json-schema-spec/go.mod \
	implementations/go-json-schema-spec/go.sum \
	implementations/go-json-schema-spec/main.go \
	implementations/go-json-schema-spec/Dockerfile
	docker build -t jsonschema-benchmark/go-json-schema-spec implementations/go-json-schema-spec
	touch $@

dist/results/go-json-schema-spec/%: \
	implementations/go-json-schema-spec/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-json-schema-spec
	@$(call docker_run,go-json-schema-spec,/workspace/$(dir $(word 2,$^)))

# GO / KAPTINLIN

implementations/go-kaptinlin/.dockertimestamp: \
	implementations/go-kaptinlin/memory-wrapper.sh \
	implementations/go-kaptinlin/go.mod \
	implementations/go-kaptinlin/go.sum \
	implementations/go-kaptinlin/main.go \
	implementations/go-kaptinlin/Dockerfile
	docker build -t jsonschema-benchmark/go-kaptinlin implementations/go-kaptinlin
	touch $@

dist/results/go-kaptinlin/%: \
	implementations/go-kaptinlin/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-kaptinlin
	@$(call docker_run,go-kaptinlin,/workspace/$(dir $(word 2,$^)))

# GO / KATYDID-AUTO WITH REFLECT PARSER

implementations/go-katydid-auto-reflect/.dockertimestamp: \
	implementations/go-katydid-auto-reflect/memory-wrapper.sh \
	implementations/go-katydid-auto-reflect/go.mod \
	implementations/go-katydid-auto-reflect/go.sum \
	implementations/go-katydid-auto-reflect/main.go \
	implementations/go-katydid-auto-reflect/Dockerfile
	docker build -t jsonschema-benchmark/go-katydid-auto-reflect implementations/go-katydid-auto-reflect
	touch $@

dist/results/go-katydid-auto-reflect/%: \
	implementations/go-katydid-auto-reflect/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-katydid-auto-reflect
	@$(call docker_run,go-katydid-auto-reflect,/workspace/$(dir $(word 2,$^)))

# GO / KATYDID-AUTO WITH JSON PARSER

implementations/go-katydid-auto-json/.dockertimestamp: \
	implementations/go-katydid-auto-json/memory-wrapper.sh \
	implementations/go-katydid-auto-json/go.mod \
	implementations/go-katydid-auto-json/go.sum \
	implementations/go-katydid-auto-json/main.go \
	implementations/go-katydid-auto-json/Dockerfile
	docker build -t jsonschema-benchmark/go-katydid-auto-json implementations/go-katydid-auto-json
	touch $@

dist/results/go-katydid-auto-json/%: \
	implementations/go-katydid-auto-json/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-katydid-auto-json
	@$(call docker_run,go-katydid-auto-json,/workspace/$(dir $(word 2,$^)))

# GO / KATYDID-MEM WITH REFLECT PARSER

implementations/go-katydid-mem-reflect/.dockertimestamp: \
	implementations/go-katydid-mem-reflect/memory-wrapper.sh \
	implementations/go-katydid-mem-reflect/go.mod \
	implementations/go-katydid-mem-reflect/go.sum \
	implementations/go-katydid-mem-reflect/main.go \
	implementations/go-katydid-mem-reflect/Dockerfile
	docker build -t jsonschema-benchmark/go-katydid-mem-reflect implementations/go-katydid-mem-reflect
	touch $@

dist/results/go-katydid-mem-reflect/%: \
	implementations/go-katydid-mem-reflect/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-katydid-mem-reflect
	@$(call docker_run,go-katydid-mem-reflect,/workspace/$(dir $(word 2,$^)))

# GO / KATYDID-MEM WITH REFLECT JSON

implementations/go-katydid-mem-json/.dockertimestamp: \
	implementations/go-katydid-mem-json/memory-wrapper.sh \
	implementations/go-katydid-mem-json/go.mod \
	implementations/go-katydid-mem-json/go.sum \
	implementations/go-katydid-mem-json/main.go \
	implementations/go-katydid-mem-json/Dockerfile
	docker build -t jsonschema-benchmark/go-katydid-mem-json implementations/go-katydid-mem-json
	touch $@

dist/results/go-katydid-mem-json/%: \
	implementations/go-katydid-mem-json/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-katydid-mem-json
	@$(call docker_run,go-katydid-mem-json,/workspace/$(dir $(word 2,$^)))

# GO / SANTHOSH_TEKURI

implementations/go-santhosh-tekuri/.dockertimestamp: \
	implementations/go-santhosh-tekuri/memory-wrapper.sh \
	implementations/go-santhosh-tekuri/go.mod \
	implementations/go-santhosh-tekuri/go.sum \
	implementations/go-santhosh-tekuri/main.go \
	implementations/go-santhosh-tekuri/Dockerfile
	docker build -t jsonschema-benchmark/go-santhosh-tekuri implementations/go-santhosh-tekuri
	touch $@

dist/results/go-santhosh-tekuri/%: \
	implementations/go-santhosh-tekuri/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-santhosh-tekuri
	@$(call docker_run,go-santhosh-tekuri,/workspace/$(dir $(word 2,$^)))

# HYPERJUMP

implementations/hyperjump/.dockertimestamp: \
	implementations/hyperjump/memory-wrapper.sh \
	implementations/hyperjump/main.mjs \
	implementations/hyperjump/package.json \
	implementations/hyperjump/Dockerfile
	docker build -t jsonschema-benchmark/hyperjump implementations/hyperjump
	touch $@

dist/results/hyperjump/%: \
	implementations/hyperjump/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/hyperjump
	@$(call docker_run,hyperjump,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# JSONCONS

implementations/jsoncons/.dockertimestamp: \
	implementations/jsoncons/memory-wrapper.sh \
	implementations/jsoncons/CMakeLists.txt \
	implementations/jsoncons/vcpkg.json \
	implementations/jsoncons/vcpkg-configuration.json \
	implementations/jsoncons/main.cc \
	implementations/jsoncons/Dockerfile
	docker build -t jsonschema-benchmark/jsoncons implementations/jsoncons
	touch $@

dist/results/jsoncons/%: \
	implementations/jsoncons/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsoncons
	@$(call docker_run,jsoncons,/workspace/$(dir $(word 2,$^)))

# DOTNET / CORVUS

implementations/corvus/.dockertimestamp: \
	implementations/corvus/memory-wrapper.sh \
	implementations/corvus/bench.csproj \
	implementations/corvus/Program.cs \
	implementations/corvus/generate-and-run.sh \
	implementations/corvus/Dockerfile
	docker build -t jsonschema-benchmark/corvus implementations/corvus
	touch $@

dist/results/corvus/%: \
	implementations/corvus/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus
	@$(call docker_run,corvus,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# SCHEMASAFE

implementations/schemasafe/.dockertimestamp: \
	implementations/schemasafe/memory-wrapper.sh \
	implementations/schemasafe/main.mjs \
	implementations/schemasafe/package.json \
	implementations/schemasafe/package-lock.json \
	implementations/schemasafe/Dockerfile
	docker build -t jsonschema-benchmark/schemasafe implementations/schemasafe
	touch $@

dist/results/schemasafe/%: \
	implementations/schemasafe/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/schemasafe
	@$(call docker_run,schemasafe,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# JsonSchema.net

implementations/jsdotnet/.dockertimestamp: \
	implementations/jsdotnet/memory-wrapper.sh \
	implementations/jsdotnet/bench.csproj \
	implementations/jsdotnet/Program.cs \
	implementations/jsdotnet/Dockerfile
	docker build -t jsonschema-benchmark/jsdotnet implementations/jsdotnet
	touch $@

dist/results/jsdotnet/%: \
	implementations/jsdotnet/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsdotnet
	@$(call docker_run,jsdotnet,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# kmp

implementations/kmp/.dockertimestamp: \
	implementations/kmp/memory-wrapper.sh \
	implementations/kmp/app/src/main/kotlin/io/github/sourcemeta/App.kt \
	implementations/kmp/app/build.gradle.kts \
	implementations/kmp/gradle/libs.versions.toml \
	implementations/kmp/gradle/wrapper/gradle-wrapper.properties \
	implementations/kmp/run.sh \
	implementations/kmp/Dockerfile
	docker build -t jsonschema-benchmark/kmp implementations/kmp
	touch $@

dist/results/kmp/%: \
	implementations/kmp/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/kmp
	@$(call docker_run,kmp,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# networknt

implementations/networknt/.dockertimestamp: \
	implementations/networknt/memory-wrapper.sh \
	implementations/networknt/app/src/main/java/io/github/sourcemeta/App.java \
	implementations/networknt/app/build.gradle.kts \
	implementations/networknt/gradle/libs.versions.toml \
	implementations/networknt/gradle/wrapper/gradle-wrapper.properties \
	implementations/networknt/run.sh \
	implementations/networknt/Dockerfile
	docker build -t jsonschema-benchmark/networknt implementations/networknt
	touch $@

dist/results/networknt/%: \
	implementations/networknt/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/networknt
	@$(call docker_run,networknt,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# opis

implementations/opis/.dockertimestamp: \
	implementations/opis/memory-wrapper.sh \
	implementations/opis/main.php \
	implementations/opis/composer.json \
	implementations/opis/composer.lock \
	implementations/opis/Dockerfile
	docker build -t jsonschema-benchmark/opis implementations/opis
	touch $@

dist/results/opis/%: \
	implementations/opis/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/opis
	@$(call docker_run,opis,/workspace/$(dir $(word 2,$^)))

# jsv

implementations/jsv/.dockertimestamp: \
	implementations/jsv/memory-wrapper.sh \
	implementations/jsv/benchmark.exs \
	implementations/jsv/config/config.exs \
	implementations/jsv/mix.exs \
	implementations/jsv/Dockerfile
	docker build -t jsonschema-benchmark/jsv implementations/jsv
	touch $@

dist/results/jsv/%: \
	implementations/jsv/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsv
	@$(call docker_run,jsv,/workspace/$(dir $(word 2,$^)))
