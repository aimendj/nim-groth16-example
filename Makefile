.PHONY: help setup build run

help:
	@echo "Available tasks:"
	@echo "  make setup              - Initialize and update submodules"
	@echo "  make build              - Build the Nim example"
	@echo "  make run ZKEY=... WTNS=... - Run the example with zkey and witness files"

setup:
	@echo "Setting up submodules..."
	git submodule update --init --recursive
	@echo "Checking out constantine branch..."
	cd deps/constantine && git checkout v0.2.0-fix-nimble-windows 2>/dev/null || true
	@echo "Submodules setup complete!"

build:
	@echo "Building Nim example..."
	nim c --threads:on --mm:arc --path:nim-groth16 --path:deps/nim-taskpools --path:deps/constantine src/example.nim
	@echo "Build complete!"

run:
	nim c -r --threads:on --mm:arc --path:nim-groth16 --path:deps/nim-taskpools --path:deps/constantine src/example.nim $(ZKEY) $(WTNS)
