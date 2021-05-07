test:
	bats -t test/test.bats

test-watch:
	nodemon -w src -w test -e bash,bats --exec 'bats -t test/*.bats'

build-docker:
	docker build . -t schemachain:latest

.PHONY: test test-watch build-docker
