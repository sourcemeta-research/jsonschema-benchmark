.DEFAULT_GOAL := all
SCHEMAS = $(notdir $(wildcard schemas/*))
IMPLEMENTATIONS = $(notdir $(wildcard implementations/*))

.PHONY: clean
clean: ; rm -rf dist implementations/ajv/node_modules
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

dist/results/jsontoolkit/%: \
	implementations/jsontoolkit/CMakeLists.txt \
	implementations/jsontoolkit/main.cc \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/jsontoolkit dist/temp/jsontoolkit
	[ -d $(word 2,$|)/repo ] && git -C $(word 2,$|)/repo pull || git clone https://github.com/sourcemeta/jsontoolkit $(word 2,$|)/repo
	cmake -S $(dir $<) -B $(word 2,$|)/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
	cmake --build $(word 2,$|)/build --config Release --parallel 4
	$(word 2,$|)/build/jsontoolkit_benchmark $(dir $(word 3,$^)) > $@

# AJV

dist/results/ajv/%: \
	implementations/ajv/main.mjs \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	implementations/ajv/package.json \
	implementations/ajv/package-lock.json \
	| dist/results/ajv
	npm ci --prefix implementations/ajv
	node implementations/ajv/main.mjs $(word 2,$^) $(word 3,$^) > $@

# BOON

dist/results/boon/%: \
	implementations/boon/src/main.rs \
	implementations/boon/Cargo.toml \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/boon
	cargo run --manifest-path implementations/boon/Cargo.toml --release $(dir $(word 3,$^)) > $@

# JSON_SCHEMER

dist/results/json_schemer/%: \
	implementations/json_schemer/main.rb \
	implementations/json_schemer/Gemfile.lock \
	schemas/%/schema.json \
	schemas/%/instances.jsonl \
	| dist/results/json_schemer
	bundle exec --gemfile implementations/json_schemer/Gemfile ruby implementations/json_schemer/main.rb schemas/example $(dir $(word 3,$^)) > $@

