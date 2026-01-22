# Nim Groth16 Example

Simple example of using [nim-groth16](https://github.com/durability-labs/nim-groth16) to generate and verify Groth16 proofs. Works with circom/snarkjs circuits on BN254.

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

The example loads the zkey and witness, generates a proof, then verifies it.

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

You'll need to create your `.zkey` and `.wtns` files using circom and snarkjs. The workflow is:

1. Write a `.circom` circuit
2. Compile to R1CS
3. Run trusted setup to get `.zkey`
4. Calculate witness to get `.wtns`

See the [circom docs](https://docs.circom.io/) for details.

## Links

- [nim-groth16](https://github.com/durability-labs/nim-groth16)
- [circom](https://github.com/iden3/circom)
- [snarkjs](https://github.com/iden3/snarkjs)
