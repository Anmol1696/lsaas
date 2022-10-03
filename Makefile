TARGET = target/wasm32-unknown-unknown/release
CONFIG_DIR = k8s/base

.PHONY: build-all build-controller build-host build-callback

build-all: build-controller build-host build-callback

build-lib:
	cd packages/simple-ica && cargo schema

build-controller:
	cd contracts/simple-ica-controller && RUSTFLAGS='-C link-arg=-s' cargo wasm

build-callback:
	cd contracts/callback-capturer && RUSTFLAGS='-C link-arg=-s' cargo wasm

build-host: build-lib
	cd contracts/simple-ica-host && RUSTFLAGS='-C link-arg=-s' cargo wasm
