test:
	bats -t test/test.bats

test-watch:
	nodemon -w src -w test -e bash,bats --exec 'clear; bats -t test/*.bats'

dist/schemachain: src/*.incl.bash
	mkdir -p dist
	(echo -e '#!/bin/bash\nset -eu\n'; cat src/*.incl.bash; echo 'dispatch_command $$@') >$@
	chmod +x $@

build-docker: dist/schemachain
	docker build . -t schemachain:latest

build-docker-watch:
	nodemon -w src -w Dockerfile -w test -e bash,bats --exec 'make test && make build-docker'

build: dist/schemachain

build-watch:
	nodemon -w src -e bash --exec 'make dist/schemachain && cp dist/schemachain /home/bard/projects/syncplayer/modules/postgres/vendor'

.PHONY: test test-watch build build-watch build-docker build-docker-watch
