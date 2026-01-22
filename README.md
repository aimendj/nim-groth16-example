# Nim Groth16 Example

Simple example of using [nim-groth16](https://github.com/durability-labs/nim-groth16) to generate and verify Groth16 proofs. Works with circom/snarkjs circuits on BN254.

**Groth16** is a zk-SNARK proof system that allows you to:
- **Prove**: Generate a proof that you know private inputs satisfying a circuit's constraints
- **Verify**: Check that a proof is valid using the Groth16 verification algorithm (pairing-based check)

## Setup

```bash
make setup
```

This pulls all submodules including nim-groth16 and its dependencies (nim-taskpools and constantine with the correct branch).

## Building

```bash
make build
```

This builds the example using the dependencies from git submodules (no nimble required).

Or compile directly:
```bash
nim c --threads:on --mm:arc --path:nim-groth16 --path:deps/nim-taskpools --path:deps/constantine src/example.nim
```

The dependencies are managed as git submodules, ensuring the correct versions are used.

## Running

You need a `.zkey` and `.wtns` file from a circom circuit:

```bash
./src/example circuit.zkey witness.wtns
```

The example:
1. Loads the **zkey** (proving key) and **witness** files
2. **Generates a Groth16 proof** using `generateProof(zkey, witness)` - uses both the proving key and witness to create a cryptographic proof
3. **Extracts the verification key** from the zkey using `extractVKey(zkey)`
4. **Verifies the proof** using `verifyProof(vkey, proof)` - uses only the verification key and proof (not the witness)

**Important**: 
- **Proving** requires: zkey (proving key) + witness (private inputs)
- **Verifying** requires: vkey (verification key) + proof (no witness needed!)

The verification uses elliptic curve pairings to check that the proof satisfies the mathematical relationship without needing access to the private inputs (witness).

Or use the make task:

```bash
make run ZKEY=circuit.zkey WTNS=witness.wtns
```

## Files

- `src/example.nim` - Main example code
- `nim-groth16/` - The groth16 library (submodule)
- `deps/nim-taskpools/` - Task pools library (submodule)
- `deps/constantine/` - Cryptographic library (submodule, branch: v0.2.0-fix-nimble-windows)

## Getting Circuit Files

You need `.zkey` (proving key) and `.wtns` (witness) files to run the example.

### Prerequisites

Install `circom` and `snarkjs`:
```bash
npm install -g circom snarkjs
```

### Quick Start

Generate all circuit files at once:
```bash
make circuit-all
```

This will:
1. Create an example `circuit.circom` file
2. Compile it to `.r1cs` and `.wasm`
3. Generate powers-of-tau file
4. Create the `.zkey` file
5. Generate the `.wtns` file with default inputs

Then run:
```bash
make run ZKEY=circuits/circuit.zkey WTNS=circuits/circuit.wtns
```

### Step by Step

You can also run each step individually:

**Step 1: Create circuit file**
```bash
make circuit-init
```
Creates `circuits/circuit.circom` with an example Multiplier circuit. This is the arithmetic circuit that defines what computation you want to prove. 

The example circuit multiplies two private inputs `a` and `b` and constrains the output to equal 15 (a public value). The proof demonstrates that you know factors `a` and `b` such that `a * b = 15`, without revealing what those factors are. For example, you could prove you know `a=3, b=5` or `a=1, b=15`, etc., without revealing which specific factors you used.

```circom
template Multiplier() {
    signal input a;
    signal input b;
    signal output c;
    c <== a * b;
    // Constrain output to public value 15
    c === 15;
}

component main = Multiplier();
```

**Step 2: Compile circuit**
```bash
make circuit-compile
```
Compiles the `.circom` circuit file into:
- `circuit.r1cs` - Rank-1 Constraint System file containing the mathematical constraints that represent your circuit
- `circuit.wasm` - WebAssembly file used to calculate the witness (the values that satisfy the constraints)

**Step 3: Generate powers-of-tau**
```bash
make circuit-pot
```
Generates a powers-of-tau file (`pot.ptau`) which is the first phase of the trusted setup ceremony. This creates the structured reference string (SRS) needed for Groth16 proofs. The ceremony includes contributions and a random beacon to ensure security.

This will prompt you for random input during the contribution steps (for security). Just type random text and press Enter when prompted.

Or with custom size (default is 12 for 2^12 = 4096 constraints):
```bash
make circuit-pot POT_SIZE=14
```
Use a larger size for circuits with more constraints.

**Step 4: Generate .zkey file**
```bash
make circuit-zkey
```
Creates the proving key (`.zkey` file) through the second phase of the trusted setup. This is circuit-specific and combines the powers-of-tau with your circuit's R1CS constraints. The ceremony includes contributions and a random beacon.

This will also prompt you for random input during the contribution steps. Type random text and press Enter when prompted.

Requires `circuit.r1cs` and `pot.ptau` from previous steps.

**Step 5: Generate .wtns file**
```bash
make circuit-wtns
```
Calculates the witness file (`.wtns`) which contains all the intermediate values that satisfy your circuit's constraints for a given input. The witness proves you know valid inputs that produce the claimed output.

Uses default input `{"a": 3, "b": 5}`. For custom input:
```bash
make circuit-wtns INPUT=myinput.json
```

### Custom Circuit Name

Use a different circuit name:
```bash
make circuit-all CIRCUIT_NAME=mycircuit
```

This will create `circuits/mycircuit.circom`, `circuits/mycircuit.zkey`, etc.

## Links

- [nim-groth16](https://github.com/durability-labs/nim-groth16)
- [circom](https://github.com/iden3/circom)
- [snarkjs](https://github.com/iden3/snarkjs)
