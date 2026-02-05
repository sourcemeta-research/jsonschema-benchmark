.DEFAULT_GOAL := all
SCHEMAS = $(notdir $(wildcard schemas/*))
ALL_IMPLEMENTATIONS = $(notdir $(wildcard implementations/*))
ifeq ($(NO_IGNORE),yes)
IMPLEMENTATIONS ?= $(ALL_IMPLEMENTATIONS)
else
IMPLEMENTATIONS ?= $(filter-out $(patsubst implementations/%/,%,$(dir $(wildcard implementations/*/.benchmark-ignore))), $(ALL_IMPLEMENTATIONS))
endif
RUNS := 3
BLAZE_BRANCH ?= main

.PHONY: clean
clean: ; rm -rf dist implementations/*/.dockertimestamp
dist: ; mkdir $@
dist/results: | dist ; mkdir $@
dist/results/plots: | dist/results ; mkdir $@
dist/results/plots/schemas: | dist/results/plots ; mkdir $@
dist/temp: | dist ; mkdir $@
define PREPARE_IMPLEMENTATION
dist/results/$1: | dist/results ; mkdir $$@
dist/temp/$1: | dist/temp ; mkdir $$@
ALL_TARGETS += $$(addprefix dist/results/$1/,$(SCHEMAS))
endef
ALL_PLOTS := $(foreach schema,$(SCHEMAS),dist/results/plots/schemas/$(schema).png)
ALL_SCHEMAS := $(foreach schema,$(SCHEMAS),schemas/$(schema)/schema-noformat.json)
ALL_INSTANCES := $(foreach schema,$(SCHEMAS),schemas/$(schema)/instances.jsonl)
$(foreach implementation,$(IMPLEMENTATIONS),$(eval $(call PREPARE_IMPLEMENTATION,$(implementation))))
dist/report.csv: report.sh $(ALL_TARGETS) | dist ; ./$< $(ALL_TARGETS) > $@
dist/summary.csv: \
	$(ALL_SCHEMAS) \
	$(ALL_INSTANCES) \
	dataset_summary.sh
	./dataset_summary.sh csv > $@
dist/results/plots/compile.svg dist/results/plots/compile.png: \
	dist/report.csv \
	dist/summary.csv \
	plot_compile.py
	uv run python plot_compile.py
dist/results/plots/schemas/%.png: \
	dist/results/plots/schemas \
	dist/report.csv \
	plot.py \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl
	uv run python plot.py
plots: $(ALL_PLOTS)
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
		if ! grep '.*,.*,' $@.tmp > /dev/null; then echo -n "0,0,0," >> $@ ; cat $@.tmp  >> $@ ; else cat $@.tmp >> $@ ; fi ; \
		sed -i "$$ s/$$/,$$STATUS/" $@ ; \
		rm -f $@.tmp ; \
	done
endef

list:
	@echo $(IMPLEMENTATIONS) | tr ' ' '\n'

schemas/%/schema-noformat.json: schemas/%/schema.json
	dts $< -o gron | grep -v '\.format =' | dts -i gron -o json -j .json > $@

implementations/%/memory-wrapper.sh: memory-wrapper.sh
	cp -p $< $@

# Blaze

# Always try to build the Blaze image, let Docker cache things
.PHONY: implementations/blaze/.dockertimestamp
implementations/blaze/.dockertimestamp: \
	implementations/blaze/memory-wrapper.sh \
	implementations/blaze/CMakeLists.txt \
	implementations/blaze/main.cc \
	implementations/blaze/Dockerfile
	docker build --build-arg BLAZE_BRANCH=$(BLAZE_BRANCH) -t jsonschema-benchmark/blaze implementations/blaze
	touch $@

dist/results/blaze/%: \
	implementations/blaze/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/blaze
	@$(call docker_run,blaze,/workspace/$(dir $(word 2,$^)))

# AJV

implementations/ajv/.dockertimestamp: \
	implementations/ajv/memory-wrapper.sh \
	implementations/ajv/main.mjs \
	implementations/ajv/package.json \
	implementations/ajv/package-lock.json \
	implementations/ajv/Dockerfile
	docker build -t jsonschema-benchmark/ajv implementations/ajv
	touch $@

dist/results/ajv/%: \
	implementations/ajv/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/ajv
	@$(call docker_run,ajv,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# AJV with bun

implementations/ajv-bun/.dockertimestamp: \
	implementations/ajv-bun/memory-wrapper.sh \
	implementations/ajv/main.mjs \
	implementations/ajv-bun/package.json \
	implementations/ajv-bun/bun.lockb \
	implementations/ajv-bun/Dockerfile
	cp implementations/ajv/main.mjs implementations/ajv-bun
	docker build -t jsonschema-benchmark/ajv-bun implementations/ajv-bun
	touch $@

dist/results/ajv-bun/%: \
	implementations/ajv-bun/.dockertimestamp \
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/boon
	@$(call docker_run,boon,/workspace/$(dir $(word 2,$^)))

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
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/json_schemer
	@$(call docker_run,json_schemer,/workspace/$(dir $(word 3,$^)))

# PYTHON / JSONSCHEMA

implementations/py-jsonschema/.dockertimestamp: \
	implementations/py-jsonschema/memory-wrapper.sh \
	implementations/py-jsonschema/validate.py \
	implementations/py-jsonschema/pyproject.toml \
	implementations/py-jsonschema/uv.lock \
	implementations/py-jsonschema/Dockerfile
	docker build -t jsonschema-benchmark/py-jsonschema implementations/py-jsonschema
	touch $@

dist/results/py-jsonschema/%: \
	implementations/py-jsonschema/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/py-jsonschema
	@$(call docker_run,py-jsonschema,/workspace/$(dir $(word 2,$^)))

# GO / JSONSCHEMA

implementations/go-jsonschema/.dockertimestamp: \
	implementations/go-jsonschema/memory-wrapper.sh \
	implementations/go-jsonschema/go.mod \
	implementations/go-jsonschema/go.sum \
	implementations/go-jsonschema/main.go \
	implementations/go-jsonschema/Dockerfile
	docker build -t jsonschema-benchmark/go-jsonschema implementations/go-jsonschema
	touch $@

dist/results/go-jsonschema/%: \
	implementations/go-jsonschema/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/go-jsonschema
	@$(call docker_run,go-jsonschema,/workspace/$(dir $(word 2,$^)))

# HYPERJUMP

implementations/hyperjump/.dockertimestamp: \
	implementations/hyperjump/memory-wrapper.sh \
	implementations/hyperjump/main.mjs \
	implementations/hyperjump/package.json \
	implementations/hyperjump/package-lock.json \
	implementations/hyperjump/Dockerfile
	docker build -t jsonschema-benchmark/hyperjump implementations/hyperjump
	touch $@

dist/results/hyperjump/%: \
	implementations/hyperjump/.dockertimestamp \
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/kmp
	@$(call docker_run,kmp,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# networknt

implementations/networknt/.dockertimestamp: \
	implementations/networknt/memory-wrapper.sh \
	implementations/networknt/app/src/main/java/io/github/sourcemeta/*.java \
	implementations/networknt/app/build.gradle.kts \
	implementations/networknt/gradle/libs.versions.toml \
	implementations/networknt/gradle/wrapper/gradle-wrapper.properties \
	implementations/networknt/run.sh \
	implementations/networknt/Dockerfile
	docker build -t jsonschema-benchmark/networknt implementations/networknt
	touch $@

dist/results/networknt/%: \
	implementations/networknt/.dockertimestamp \
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/opis
	@$(call docker_run,opis,/workspace/$(dir $(word 2,$^)))

# jsv

implementations/jsv/.dockertimestamp: \
	implementations/jsv/memory-wrapper.sh \
	implementations/jsv/benchmark.exs \
	implementations/jsv/config/config.exs \
	implementations/jsv/mix.exs \
	implementations/jsv/mix.lock \
	implementations/jsv/Dockerfile
	docker build -t jsonschema-benchmark/jsv implementations/jsv
	touch $@

dist/results/jsv/%: \
	implementations/jsv/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/jsv
	@$(call docker_run,jsv,/workspace/$(dir $(word 2,$^)))
