.DEFAULT_GOAL := all
SCHEMAS = $(notdir $(wildcard schemas/*))
IMPLEMENTATIONS ?= $(notdir $(wildcard implementations/*))
RUNS := 3

.PHONY: clean
clean: ; rm -rf dist implementations/*/.dockertimestamp
dist: ; mkdir $@
dist/results: | dist ; mkdir $@
dist/results/plots: | dist/results ; mkdir $@
dist/temp: | dist ; mkdir $@
define PREPARE_IMPLEMENTATION
dist/results/$1: | dist/results ; mkdir $$@
dist/temp/$1: | dist/temp ; mkdir $$@
ALL_TARGETS += $$(addprefix dist/results/$1/,$(SCHEMAS))
endef
ALL_PLOTS := $(foreach schema,$(SCHEMAS),dist/results/plots/$(schema).png)
$(foreach implementation,$(IMPLEMENTATIONS),$(eval $(call PREPARE_IMPLEMENTATION,$(implementation))))
dist/report.csv: report.sh $(ALL_TARGETS) | dist ; ./$< $(ALL_TARGETS) > $@
dist/results/plots/%.png: \
	dist/results/plots \
	dist/report.csv \
	plot.py \
	schemas/%/schema.json \
	schemas/%/instances.jsonl
	uv run python plot.py
plots: $(ALL_PLOTS)
.PHONY: all
all: dist/report.csv ; cat $<

define docker_run
  $(eval $@_TOOL = $(1))
  $(eval $@_INPUT = $(2))
	rm -f $@
	for i in $(shell seq 1 $(RUNS)) ; do \
		docker run --rm -v $(CURDIR):/workspace jsonschema-benchmark/$($@_TOOL) $($@_INPUT) > $@.tmp ; \
		STATUS=$$? ; \
		if [ ! -s $@.tmp ]; then echo "0,0,0" >> $@ ; else cat $@.tmp >> $@ ; fi ; \
		sed -i "$$ s/$$/,$$STATUS/" $@ ; \
		rm -f $@.tmp ; \
	done
endef

# Blaze

implementations/blaze/.dockertimestamp: \
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

implementations/blaze-nodejs/.dockertimestamp: \
	implementations/blaze-nodejs/main.mjs \
	implementations/blaze-nodejs/Dockerfile
	docker build -t jsonschema-benchmark/blaze-nodejs implementations/blaze-nodejs
	touch $@

dist/results/blaze-nodejs/%: \
	implementations/blaze-nodejs/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/blaze-nodejs
	@$(call docker_run,blaze-nodejs,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# AJV

implementations/ajv/.dockertimestamp: \
	implementations/ajv/main.mjs \
	implementations/ajv/package.json \
	implementations/ajv/package-lock.json \
	implementations/ajv/Dockerfile
	docker build -t jsonschema-benchmark/ajv implementations/ajv
	touch $@

dist/results/ajv/%: \
	implementations/ajv/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/ajv
	@$(call docker_run,ajv,/workspace/$(word 2,$^) /workspace/$(word 3,$^))

# BOON

implementations/boon/.dockertimestamp: \
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

# JSON_SCHEMER

implementations/json_schemer/.dockertimestamp: \
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

implementations/python-jsonschema/.dockertimestamp: \
	implementations/python-jsonschema/validate.py \
	implementations/python-jsonschema/pyproject.toml \
	implementations/python-jsonschema/uv.lock \
	implementations/python-jsonschema/Dockerfile
	docker build -t jsonschema-benchmark/python-jsonschema implementations/python-jsonschema
	touch $@

dist/results/python-jsonschema/%: \
	implementations/python-jsonschema/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/python-jsonschema
	@$(call docker_run,python-jsonschema,/workspace/$(dir $(word 2,$^)))

# GO / JSONSCHEMA

implementations/go-jsonschema/.dockertimestamp: \
	implementations/go-jsonschema/go.mod \
	implementations/go-jsonschema/go.sum \
	implementations/go-jsonschema/main.go \
	implementations/go-jsonschema/Dockerfile
	docker build -t jsonschema-benchmark/go-jsonschema implementations/go-jsonschema
	touch $@

dist/results/go-jsonschema/%: \
	implementations/go-jsonschema/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/go-jsonschema
	@$(call docker_run,go-jsonschema,/workspace/$(dir $(word 2,$^)))

# HYPERJUMP

implementations/hyperjump/.dockertimestamp: \
	implementations/hyperjump/main.mjs \
	implementations/hyperjump/package.json \
	implementations/hyperjump/package-lock.json \
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
