PROCESS=wasmd
DOCKER := $(shell which docker)
DOCKER_TAG_NAME := hackwasm

docker-build:
	$(DOCKER) buildx build $(DOCKER_ARGS) \
		-t persistenceone/$(PROCESS):$(DOCKER_TAG_NAME) \
		. -f Dockerfile.$(PROCESS)

docker-build-linux:
	$(MAKE) docker-build DOCKER_ARGS="--platform linux/amd64" DOCKER_TAG_NAME="hackwasm-linux"

docker-build-push-linux: docker-build-linux
	$(DOCKER) push persistenceone/$(PROCESS):hackwasm-linux

docker-build-push: docker-build
	$(DOCKER) push persistenceone/$(PROCESS):$(DOCKER_TAG_NAME)

docker-run:
	$(DOCKER) run --rm -it persistenceone/$(PROCESS):$(DOCKER_TAG_NAME) /bin/bash
