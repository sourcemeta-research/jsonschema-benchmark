.DEFAULT_GOAL := all
SCHEMAS = $(notdir $(wildcard schemas/*))
IMPLEMENTATIONS = $(notdir $(wildcard implementations/*))

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

# JSON Toolkit

implementations/jsontoolkit/.dockertimestamp: \
	implementations/jsontoolkit/CMakeLists.txt \
	implementations/jsontoolkit/main.cc \
	implementations/jsontoolkit/Dockerfile
	docker build -t jsonschema-benchmark/jsontoolkit implementations/jsontoolkit
	touch $@

dist/results/jsontoolkit/%: \
	implementations/jsontoolkit/.dockertimestamp \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsontoolkit
	docker run --rm -v $(CURDIR):/workspace jsonschema-benchmark/jsontoolkit /workspace/$(dir $(word 2,$^)) > $@

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
	docker run --rm -v $(CURDIR):/workspace jsonschema-benchmark/ajv /workspace/$(word 2,$^) /workspace/$(word 3,$^) > $@

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
	docker run --rm -v $(CURDIR):/workspace jsonschema-benchmark/boon /workspace/$(dir $(word 2,$^)) > $@

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
	docker run --rm -v $(CURDIR):/workspace jsonschema-benchmark/json_schemer /workspace/$(dir $(word 3,$^)) > $@

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
	docker run --rm -v $(CURDIR):/workspace jsonschema-benchmark/python-jsonschema /workspace/$(dir $(word 2,$^)) > $@

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
	docker run --rm -v $(CURDIR):/workspace jsonschema-benchmark/go-jsonschema /workspace/$(dir $(word 2,$^)) > $@
