# Variables
CIRCUIT_NAME ?= circuit
CIRCUITS_DIR = circuits
POT_SIZE ?= 12

# Compiler flags
NIM_FLAGS = --threads:on --mm:arc --path:nim-groth16 --path:deps/nim-taskpools --path:deps/constantine

# Phony targets
.PHONY: help setup run-file-prove run-inline-prove \
        check-tools circuit-init circuit-compile circuit-pot circuit-zkey circuit-wtns circuit-all

# Default target
help:
	@echo "Available tasks:"
	@echo ""
	@echo "Setup:"
	@echo "  make setup                    - Initialize and update submodules"
	@echo ""
	@echo "Run:"
	@echo "  make run-file-prove ZKEY=... WTNS=... - Run the file-based example (uses circom/snarkjs files)"
	@echo "  make run-inline-prove A=... B=... [ZKEY=...] - Run the programmatic proof generation example"
	@echo ""
	@echo "Circuit generation (CIRCUIT_NAME=$(CIRCUIT_NAME), POT_SIZE=$(POT_SIZE)):"
	@echo "  Note: Requires circom and snarkjs (install with: npm install -g circom snarkjs)"
	@echo "  make circuit-init            - Create example circuit.circom file"
	@echo "  make circuit-compile         - Compile .circom to .r1cs and .wasm"
	@echo "  make circuit-pot              - Generate powers-of-tau file"
	@echo "  make circuit-zkey            - Generate .zkey file (requires .r1cs and pot.ptau)"
	@echo "  make circuit-wtns INPUT=...  - Generate .wtns file (requires .wasm and input.json)"
	@echo "  make circuit-all             - Run all circuit generation steps"

# Setup
setup:
	@echo "Setting up submodules..."
	git submodule update --init --recursive
	@echo "Checking out constantine branch..."
	cd deps/constantine && git checkout v0.2.0-fix-nimble-windows 2>/dev/null || true
	@echo "Submodules setup complete!"

# Run
run-file-prove:
	@if [ -z "$(ZKEY)" ] || [ -z "$(WTNS)" ]; then \
		echo "Usage: make run-file-prove ZKEY=<zkey_file> WTNS=<witness_file>"; \
		exit 1; \
	fi
	@echo "Running file-based example with $(ZKEY) and $(WTNS)..."
	nim c -r $(NIM_FLAGS) src/file_prove.nim $(ZKEY) $(WTNS)

run-inline-prove:
	@if [ -z "$(A)" ] || [ -z "$(B)" ]; then \
		echo "Usage: make run-inline-prove A=<a_value> B=<b_value> [ZKEY=<zkey_file>]"; \
		echo "  where a * b = 15"; \
		echo "  ZKEY is optional - if provided, uses real zkey; otherwise uses fake setup"; \
		exit 1; \
	fi
	@if [ -n "$(ZKEY)" ]; then \
		echo "Generating and validating proof with a=$(A), b=$(B), zkey=$(ZKEY)..."; \
		nim c -r $(NIM_FLAGS) src/inline_prove.nim $(A) $(B) $(ZKEY); \
	else \
		echo "Generating and validating proof with a=$(A), b=$(B) (using fake setup)..."; \
		nim c -r $(NIM_FLAGS) src/inline_prove.nim $(A) $(B); \
	fi

# Circuit generation
# Check for required tools
check-tools:
	@command -v circom >/dev/null 2>&1 || { echo "Error: circom is not installed. Install with: npm install -g circom"; exit 1; }
	@command -v snarkjs >/dev/null 2>&1 || { echo "Error: snarkjs is not installed. Install with: npm install -g snarkjs"; exit 1; }
	@echo "✓ circom and snarkjs are installed"

circuit-init:
	@echo "Creating example circuit file..."
	@mkdir -p $(CIRCUITS_DIR)
	@if [ ! -f $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom ]; then \
		echo "template Multiplier() {" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "    signal input a;" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "    signal input b;" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "    signal output c;" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "    c <== a * b;" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "    // Constrain output to public value 15" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "    c === 15;" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "}" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "// Proves: I know factors a and b such that a * b = 15 (public)" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "// Example: a=3, b=5 or a=1, b=15, etc." >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "component main = Multiplier();" >> $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom; \
		echo "Created $(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom"; \
	else \
		echo "$(CIRCUITS_DIR)/$(CIRCUIT_NAME).circom already exists, skipping"; \
	fi

circuit-compile: check-tools
	@echo "Compiling circuit..."
	@mkdir -p $(CIRCUITS_DIR)
	@cd $(CIRCUITS_DIR) && circom $(CIRCUIT_NAME).circom --r1cs --wasm
	@echo "Created $(CIRCUITS_DIR)/$(CIRCUIT_NAME).r1cs and $(CIRCUITS_DIR)/$(CIRCUIT_NAME).wasm"

circuit-pot: check-tools
	@echo "Generating powers-of-tau (size: $(POT_SIZE))..."
	@mkdir -p $(CIRCUITS_DIR)
	@cd $(CIRCUITS_DIR) && \
		snarkjs powersoftau new bn128 $(POT_SIZE) pot.ptau -v && \
		snarkjs powersoftau contribute pot.ptau pot_new.ptau --name="First" -v && \
		snarkjs powersoftau contribute pot_new.ptau pot.ptau --name="Second" -v && \
		snarkjs powersoftau beacon pot.ptau pot_final.ptau 010203 10 -n="Final" -v && \
		mv pot_final.ptau pot.ptau && \
		rm -f pot_new.ptau && \
		snarkjs powersoftau prepare phase2 pot.ptau pot_final.ptau -v && \
		mv pot_final.ptau pot.ptau
	@echo "Created $(CIRCUITS_DIR)/pot.ptau"

circuit-zkey: check-tools
	@echo "Generating .zkey file..."
	@cd $(CIRCUITS_DIR) && \
		snarkjs groth16 setup $(CIRCUIT_NAME).r1cs pot.ptau $(CIRCUIT_NAME)_0000.zkey && \
		snarkjs zkey contribute $(CIRCUIT_NAME)_0000.zkey $(CIRCUIT_NAME)_0001.zkey --name="First" -v && \
		snarkjs zkey contribute $(CIRCUIT_NAME)_0001.zkey $(CIRCUIT_NAME)_0002.zkey --name="Second" -v && \
		snarkjs zkey beacon $(CIRCUIT_NAME)_0002.zkey $(CIRCUIT_NAME).zkey 010203 10 -n="Final" && \
		rm -f $(CIRCUIT_NAME)_0000.zkey $(CIRCUIT_NAME)_0001.zkey $(CIRCUIT_NAME)_0002.zkey
	@echo "Created $(CIRCUITS_DIR)/$(CIRCUIT_NAME).zkey"

circuit-wtns: check-tools
	@if [ -z "$(INPUT)" ]; then \
		echo "Creating default input.json..."; \
		echo '{"a": 3, "b": 5}' > $(CIRCUITS_DIR)/input.json; \
		echo "Using default inputs: a=3, b=5 (which multiply to 15)"; \
	else \
		cp $(INPUT) $(CIRCUITS_DIR)/input.json; \
	fi
	@echo "Generating .wtns file..."
	@cd $(CIRCUITS_DIR) && snarkjs wtns calculate $(CIRCUIT_NAME).wasm input.json $(CIRCUIT_NAME).wtns
	@echo "Created $(CIRCUITS_DIR)/$(CIRCUIT_NAME).wtns"

circuit-all: circuit-init circuit-compile circuit-pot circuit-zkey circuit-wtns
	@echo ""
	@echo "Circuit files ready! Run with:"
	@echo "  make run-file-prove ZKEY=$(CIRCUITS_DIR)/$(CIRCUIT_NAME).zkey WTNS=$(CIRCUITS_DIR)/$(CIRCUIT_NAME).wtns"
