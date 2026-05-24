.PHONY: help doctor setup generate gen dev start run open build build-debug build-release test test-rust test-swift format lint clean package-mac

help:
	@printf '%s\n' "DarkRoom commands:"
	@printf '%s\n' "  make doctor        Check local toolchain setup"
	@printf '%s\n' "  make generate      Regenerate the Xcode project/workspace"
	@printf '%s\n' "  make dev           Generate, build Debug, and launch the app"
	@printf '%s\n' "  make run           Open the latest Debug app build"
	@printf '%s\n' "  make test          Run all tests"
	@printf '%s\n' "  make test-rust     Run Rust tests"
	@printf '%s\n' "  make test-swift    Run Swift/macOS tests"
	@printf '%s\n' "  make format        Format code"
	@printf '%s\n' "  make lint          Run lint checks"
	@printf '%s\n' "  make clean         Remove generated build artifacts"

doctor:
	./scripts/doctor.sh

setup:
	./scripts/setup.sh

generate:
	./scripts/generate.sh

gen: generate

dev:
	./scripts/dev.sh

start: dev

run:
	./scripts/run.sh

open: run

build:
	./scripts/build-debug.sh

build-debug:
	./scripts/build-debug.sh

build-release:
	./scripts/build-release.sh

test:
	./scripts/test.sh

test-rust:
	./scripts/test-rust.sh

test-swift:
	./scripts/test-swift.sh

format:
	./scripts/format.sh

lint:
	./scripts/lint.sh

clean:
	./scripts/clean.sh

package-mac:
	./scripts/package-mac.sh
