test:
	bats -t test/test.bats

test-watch:
	nodemon -w src -w test -e bash,bats --exec 'clear; bats -t test/*.bats'

dist/schemachain: src/*.incl.bash
	mkdir dist
	(echo -e '#!/bin/bash\nset -eu\n'; cat src/*.incl.bash; echo 'dispatch_command $$@') >$@
	chmod +x $@

build-docker: dist/schemachain
	docker build . -t schemachain:latest

build: dist/schemachain

.PHONY: test test-watch build build-docker build-docker-watch
