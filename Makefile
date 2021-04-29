test:
	bats -t test/test.bats

test-watch:
	nodemon -w src -w test -e bash,bats --exec 'bats -t test/test.bats'

build-docker:
	docker build . -t schemachain

.PHONY: test test-watch build-docker
