.DEFAULT_GOAL := all
SCHEMAS = $(notdir $(wildcard schemas/*))
IMPLEMENTATIONS = $(notdir $(wildcard implementations/*))

node_modules: package.json package-lock.json ; npm ci
.PHONY: clean
clean: ; rm -rf dist node_modules
dist: ; mkdir $@
dist/results: | dist ; mkdir $@
dist/temp: | dist ; mkdir $@
define PREPARE_IMPLEMENTATION
dist/results/$1: | dist/results ; mkdir $$@
dist/temp/$1: | dist/temp ; mkdir $$@
ALL_TARGETS += $$(addprefix dist/results/$1/,$(SCHEMAS))
endef
$(foreach implementation,$(IMPLEMENTATIONS),$(eval $(call PREPARE_IMPLEMENTATION,$(implementation))))
dist/report.csv: report.sh $(ALL_TARGETS) | dist ; ./$< $(ALL_TARGETS) > $@
.PHONY: all
all: dist/report.csv ; cat $<

# JSON Toolkit

dist/results/jsontoolkit/%: \
	implementations/jsontoolkit/CMakeLists.txt \
	implementations/jsontoolkit/main.cc \
	schemas/%/schema.json \
	schemas/%/instance.json \
	| dist/results/jsontoolkit dist/temp/jsontoolkit
	[ -d $(word 2,$|)/repo ] && git -C $(word 2,$|)/repo pull || git clone https://github.com/sourcemeta/jsontoolkit $(word 2,$|)/repo
	cmake -S $(dir $<) -B $(word 2,$|)/build -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF
	cmake --build $(word 2,$|)/build --config Release --parallel 4
	$(word 2,$|)/build/jsontoolkit_benchmark $(dir $(word 3,$^)) > $@

# AJV

dist/results/ajv/%: \
	implementations/ajv/main.js \
	schemas/%/schema.json \
	schemas/%/instance.json \
	node_modules \
	| dist/results/ajv
	node $< $(word 2,$^) $(word 3,$^) > $@
