TARGET = target/wasm32-unknown-unknown/release
CONFIG_DIR = k8s/base

.PHONY: build-all build-controller build-host build-callback

build-all: build-controller build-host build-callback

build-controller:
	cd contracts/simple-ica-controller && cargo wasm

build-callback:
	cd contracts/callback-capturer && cargo wasm

build-host:
	cd contracts/simple-ica-host && cargo wasm
