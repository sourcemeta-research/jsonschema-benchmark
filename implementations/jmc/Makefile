SHELL   = /bin/bash
.ONESHELL:

NAME    = awesome_jmc
RUN.sh  = generate-and-run.sh
VER.sh  = version.sh
MEM.sh  = memory-wrapper.sh

#
# CLEAN
#
.PHONY: clean
clean: stop
	docker rm $(NAME)
	$(RM) memory-wrapper.sh benches.txt .build .run .start

.PHONY: clean.docker
clean.docker: clean
	docker image prune -f
	docker container prune -f
	docker image rm -f $$(docker image ls | grep '^<none>' | tr -s " " " " | cut -d' ' -f 3) jmc

#
# DOCKER
#
.PHONY: build
build: .build

.build: Dockerfile $(MEM.sh) $(RUN.sh) $(VER.sh)
	docker build -t jmc -f Dockerfile .
	touch $@

$(MEM.sh): ../../memory-wrapper.sh
	cp $< $@


.PHONY: run
run: .run

.run: .build
	docker run --name $(NAME) -v ../../schemas:/schemas -dit --entrypoint /bin/sh jmc
	touch $@ .start

.PHONY: start
start: .start

.start: .run
	docker start $(NAME)
	touch $@

.PHONY: stop
stop:
	docker stop $(NAME)
	$(RM) .start

.PHONY: version
version: .start
	docker exec $(NAME) /app/version.sh

.PHONY: status
status:
	# docker volume ls
	docker container ps -a
	docker image ls -a

#
# BENCH
#
BENCH   = babelrc

.PHONY: bench
bench: .start
	docker exec $(NAME) /app/$(MEM.sh) /app/$(RUN.sh) \
	    /schemas/$(BENCH)/schema.json /schemas/$(BENCH)/instances.jsonl


BENCHES = $(sort $(basename $(dir $(wildcard ../../schemas/*/schema.json))))

.PHONY: benches
benches: .start
	for bench in $(BENCHES) ; do
	    echo "# considering $$bench"
	    $(MAKE) BENCH=$$bench bench
	done

benches.txt:
	$(MAKE) benches > $@ 2>&1
