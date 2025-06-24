SHELL   = /bin/bash
.ONESHELL:

.PHONY: build
build: memory-wrapper.sh
	docker build -t jmc -f Dockerfile .

memory-wrapper.sh: ../../memory-wrapper.sh
	cp $< $@

.PHONY: clean
clean:
	docker image prune -f
	$(RM) memory-wrapper.sh runs.txt

.PHONY: clean.docker
clean.docker:
	docker container prune -f
	docker image rm -f $$(docker image ls | grep '^<none>' | tr -s " " " " | cut -d' ' -f 3) jmc

# FIXME stop containers?
# run one bench
BENCH   = babelrc

.PHONY: run
run: build
	docker run -v ../../schemas:/schemas jmc \
	    /schemas/$(BENCH)/schema.json /schemas/$(BENCH)/instances.jsonl

# run all benches
BENCHES = $(basename $(dir $(wildcard ../../schemas/*/schema.json)))

.PHONY: runs
runs: build
	for bench in $(BENCHES) ; do
	    echo "# considering $$bench"
	    docker run -v ../../schemas:/schemas jmc \
	        /schemas/$$bench/schema.json /schemas/$$bench/instances.jsonl
	done

runs.txt: Dockerfile generate-and-run.sh memory-wrapper.sh
	$(MAKE) runs > $@ 2>&1

.PHONY: version
version: build
	docker run --entrypoint /app/version.sh jmc

.PHONY: status
status:
	# docker volume ls
	docker container ls -a
	docker image ls -a

