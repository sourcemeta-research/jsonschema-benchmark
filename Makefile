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
		if ! grep '.*,.*,.*,' $@.tmp > /dev/null; then echo -n "0,0,0,0," >> $@ ; cat $@.tmp  >> $@ ; else cat $@.tmp >> $@ ; fi ; \
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

# ATA-VALIDATOR

implementations/ata-validator/.dockertimestamp: \
	implementations/ata-validator/memory-wrapper.sh \
	implementations/ata-validator/main.mjs \
	implementations/ata-validator/package.json \
	implementations/ata-validator/package-lock.json \
	implementations/ata-validator/Dockerfile
	docker build -t jsonschema-benchmark/ata-validator implementations/ata-validator
	touch $@

dist/results/ata-validator/%: \
	implementations/ata-validator/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/ata-validator
	@$(call docker_run,ata-validator,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

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
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
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
	schemas/%/schema-noformat.json \
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

# PYTHON / JSONSCHEMA-RS (the Python bindings of the jsonschema Rust crate)

implementations/jsonschema-rs/.dockertimestamp: \
	implementations/jsonschema-rs/memory-wrapper.sh \
	implementations/jsonschema-rs/validate.py \
	implementations/jsonschema-rs/pyproject.toml \
	implementations/jsonschema-rs/uv.lock \
	implementations/jsonschema-rs/Dockerfile
	docker build -t jsonschema-benchmark/jsonschema-rs implementations/jsonschema-rs
	touch $@

dist/results/jsonschema-rs/%: \
	implementations/jsonschema-rs/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/jsonschema-rs
	@$(call docker_run,jsonschema-rs,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

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

# DOTNET / CORVUS (native AOT, interpreting the schema: the fastest start)

implementations/corvus-net-optcold/.dockertimestamp: \
	implementations/corvus-net-optcold/memory-wrapper.sh \
	implementations/corvus-net-optcold/bench.csproj \
	implementations/corvus-net-optcold/Program.cs \
	implementations/corvus-net-optcold/Dockerfile
	docker build -t jsonschema-benchmark/corvus-net-optcold implementations/corvus-net-optcold
	touch $@

dist/results/corvus-net-optcold/%: \
	implementations/corvus-net-optcold/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-net-optcold
	@$(call docker_run,corvus-net-optcold,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# DOTNET / CORVUS (the JIT, with the schema compiled to IL: the fastest warm validation)

implementations/corvus-net-optwarm/.dockertimestamp: \
	implementations/corvus-net-optwarm/memory-wrapper.sh \
	implementations/corvus-net-optwarm/bench.csproj \
	implementations/corvus-net-optwarm/Program.cs \
	implementations/corvus-net-optwarm/Dockerfile
	docker build -t jsonschema-benchmark/corvus-net-optwarm implementations/corvus-net-optwarm
	touch $@

dist/results/corvus-net-optwarm/%: \
	implementations/corvus-net-optwarm/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-net-optwarm
	@$(call docker_run,corvus-net-optwarm,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Java)

implementations/corvus-java/.dockertimestamp: \
	implementations/corvus-java/memory-wrapper.sh \
	implementations/corvus-java/src/main/java/Main.java \
	implementations/corvus-java/src/main/java/Train.java \
	implementations/corvus-java/pom.xml \
	implementations/corvus-java/Dockerfile
	docker build -t jsonschema-benchmark/corvus-java implementations/corvus-java
	touch $@

dist/results/corvus-java/%: \
	implementations/corvus-java/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-java
	@$(call docker_run,corvus-java,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Go)

implementations/corvus-go/.dockertimestamp: \
	implementations/corvus-go/memory-wrapper.sh \
	implementations/corvus-go/go.mod \
	implementations/corvus-go/go.sum \
	implementations/corvus-go/main.go \
	implementations/corvus-go/Dockerfile
	docker build -t jsonschema-benchmark/corvus-go implementations/corvus-go
	touch $@

dist/results/corvus-go/%: \
	implementations/corvus-go/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-go
	@$(call docker_run,corvus-go,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Object Pascal)

implementations/corvus-pas/.dockertimestamp: \
	implementations/corvus-pas/memory-wrapper.sh \
	implementations/corvus-pas/main.pas \
	implementations/corvus-pas/Dockerfile
	docker build -t jsonschema-benchmark/corvus-pas implementations/corvus-pas
	touch $@

dist/results/corvus-pas/%: \
	implementations/corvus-pas/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-pas
	@$(call docker_run,corvus-pas,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (R)

implementations/corvus-r/.dockertimestamp: \
	implementations/corvus-r/memory-wrapper.sh \
	implementations/corvus-r/main.R \
	implementations/corvus-r/Dockerfile
	docker build -t jsonschema-benchmark/corvus-r implementations/corvus-r
	touch $@

dist/results/corvus-r/%: \
	implementations/corvus-r/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-r
	@$(call docker_run,corvus-r,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Julia)

implementations/corvus-jl/.dockertimestamp: \
	implementations/corvus-jl/memory-wrapper.sh \
	implementations/corvus-jl/Project.toml \
	implementations/corvus-jl/main.jl \
	implementations/corvus-jl/src/CorvusJsonSchemaBenchmark.jl \
	implementations/corvus-jl/Dockerfile
	docker build -t jsonschema-benchmark/corvus-jl implementations/corvus-jl
	touch $@

dist/results/corvus-jl/%: \
	implementations/corvus-jl/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-jl
	@$(call docker_run,corvus-jl,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (TypeScript)

implementations/corvus-ts/.dockertimestamp: \
	implementations/corvus-ts/memory-wrapper.sh \
	implementations/corvus-ts/main.mjs \
	implementations/corvus-ts/package.json \
	implementations/corvus-ts/package-lock.json \
	implementations/corvus-ts/Dockerfile
	docker build -t jsonschema-benchmark/corvus-ts implementations/corvus-ts
	touch $@

dist/results/corvus-ts/%: \
	implementations/corvus-ts/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-ts
	@$(call docker_run,corvus-ts,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Rust)

implementations/corvus-rs/.dockertimestamp: \
	implementations/corvus-rs/memory-wrapper.sh \
	implementations/corvus-rs/src/main.rs \
	implementations/corvus-rs/Cargo.toml \
	implementations/corvus-rs/Cargo.lock \
	implementations/corvus-rs/Dockerfile
	docker build -t jsonschema-benchmark/corvus-rs implementations/corvus-rs
	touch $@

dist/results/corvus-rs/%: \
	implementations/corvus-rs/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-rs
	@$(call docker_run,corvus-rs,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Python)

implementations/corvus-py/.dockertimestamp: \
	implementations/corvus-py/memory-wrapper.sh \
	implementations/corvus-py/validate.py \
	implementations/corvus-py/pyproject.toml \
	implementations/corvus-py/uv.lock \
	implementations/corvus-py/Dockerfile
	docker build -t jsonschema-benchmark/corvus-py implementations/corvus-py
	touch $@

dist/results/corvus-py/%: \
	implementations/corvus-py/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-py
	@$(call docker_run,corvus-py,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Python, Rust)

implementations/corvus-py-rs/.dockertimestamp: \
	implementations/corvus-py-rs/memory-wrapper.sh \
	implementations/corvus-py-rs/validate.py \
	implementations/corvus-py-rs/pyproject.toml \
	implementations/corvus-py-rs/uv.lock \
	implementations/corvus-py-rs/Dockerfile
	docker build -t jsonschema-benchmark/corvus-py-rs implementations/corvus-py-rs
	touch $@

dist/results/corvus-py-rs/%: \
	implementations/corvus-py-rs/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-py-rs
	@$(call docker_run,corvus-py-rs,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (C++)

implementations/corvus-cpp/.dockertimestamp: \
	implementations/corvus-cpp/memory-wrapper.sh \
	implementations/corvus-cpp/main.cpp \
	implementations/corvus-cpp/CMakeLists.txt \
	implementations/corvus-cpp/Dockerfile
	docker build -t jsonschema-benchmark/corvus-cpp implementations/corvus-cpp
	touch $@

dist/results/corvus-cpp/%: \
	implementations/corvus-cpp/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-cpp
	@$(call docker_run,corvus-cpp,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Ruby)

implementations/corvus-rb/.dockertimestamp: \
	implementations/corvus-rb/memory-wrapper.sh \
	implementations/corvus-rb/main.rb \
	implementations/corvus-rb/Gemfile \
	implementations/corvus-rb/Dockerfile
	docker build -t jsonschema-benchmark/corvus-rb implementations/corvus-rb
	touch $@

dist/results/corvus-rb/%: \
	implementations/corvus-rb/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-rb
	@$(call docker_run,corvus-rb,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (PHP)

implementations/corvus-php/.dockertimestamp: \
	implementations/corvus-php/memory-wrapper.sh \
	implementations/corvus-php/main.php \
	implementations/corvus-php/Dockerfile
	docker build -t jsonschema-benchmark/corvus-php implementations/corvus-php
	touch $@

dist/results/corvus-php/%: \
	implementations/corvus-php/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-php
	@$(call docker_run,corvus-php,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Perl)

implementations/corvus-pl/.dockertimestamp: \
	implementations/corvus-pl/memory-wrapper.sh \
	implementations/corvus-pl/main.pl \
	implementations/corvus-pl/Dockerfile
	docker build -t jsonschema-benchmark/corvus-pl implementations/corvus-pl
	touch $@

dist/results/corvus-pl/%: \
	implementations/corvus-pl/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-pl
	@$(call docker_run,corvus-pl,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Perl, XS)

implementations/corvus-pl-xs/.dockertimestamp: \
	implementations/corvus-pl-xs/memory-wrapper.sh \
	implementations/corvus-pl-xs/main.pl \
	implementations/corvus-pl-xs/Dockerfile
	docker build -t jsonschema-benchmark/corvus-pl-xs implementations/corvus-pl-xs
	touch $@

dist/results/corvus-pl-xs/%: \
	implementations/corvus-pl-xs/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-pl-xs
	@$(call docker_run,corvus-pl-xs,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# CORVUS (Swift)

implementations/corvus-swift/.dockertimestamp: \
	implementations/corvus-swift/memory-wrapper.sh \
	implementations/corvus-swift/Package.swift \
	implementations/corvus-swift/Sources/corvus_swift_benchmark/main.swift \
	implementations/corvus-swift/Dockerfile
	docker build -t jsonschema-benchmark/corvus-swift implementations/corvus-swift
	touch $@

dist/results/corvus-swift/%: \
	implementations/corvus-swift/.dockertimestamp \
	schemas/%/schema-noformat.json \
	schemas/%/instances.jsonl \
	| dist/results/corvus-swift
	@$(call docker_run,corvus-swift,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

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
