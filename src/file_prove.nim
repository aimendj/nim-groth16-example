##
## Example demonstrating how to use the Groth16 prover
## This example shows how to generate and verify a Groth16 proof
##

{.push raises: [ValueError, IOError, OSError, CatchableError].}

import std/[os, strutils]
import taskpools
import groth16/prover
import groth16/verifier
import groth16/files/witness
import groth16/files/zkey
import groth16/zkey_types

proc main() {.raises: [ValueError, IOError, OSError, CatchableError].} =
  ## Main example function demonstrating Groth16 proof generation and verification
  
  # Check if required files are provided
  if paramCount() < 2:
    raise newException(
      ValueError,
      "Invalid input: missing required arguments. Usage: " &
      getAppFilename() & " <zkey_file> <witness_file>"
    )
  
  let zkeyFile = paramStr(1)
  let witnessFile = paramStr(2)
  
  # Check if files exist
  if not fileExists(zkeyFile):
    raise newException(IOError, "zkey file not found: " & zkeyFile)
  
  if not fileExists(witnessFile):
    raise newException(IOError, "witness file not found: " & witnessFile)
  
  echo "=".repeat(60)
  echo "Groth16 Proof Generation and Verification Example"
  echo "=".repeat(60)
  echo ""
  
  # Parse the zkey and witness files
  echo "[1/4] Parsing zkey file: ", zkeyFile
  let zkey = parseZKey(zkeyFile)
  echo "      ✓ Zkey loaded successfully"
  echo ""
  
  echo "[2/4] Parsing witness file: ", witnessFile
  let witness = parseWitness(witnessFile)
  echo "      ✓ Witness loaded successfully"
  echo ""
  
  # Generate the proof
  echo "[3/4] Generating Groth16 proof..."
  var pool = Taskpool.new()
  let proof = generateProof(zkey, witness, pool)
  pool.shutdown()
  echo "      ✓ Proof generated successfully"
  echo "      Public IO: ", proof.publicIO
  echo ""
  
  # Extract verification key and verify the proof
  echo "[4/4] Verifying proof..."
  let vkey = extractVKey(zkey)
  let isValid = verifyProof(vkey, proof)
  
  if isValid:
    echo "      ✓ Proof verification: SUCCESS"
    echo ""
    echo "=".repeat(60)
    echo "Proof is valid!"
    echo "=".repeat(60)
  else:
    echo "      ✗ Proof verification: FAILED"
    echo ""
    echo "=".repeat(60)
    echo "Proof verification failed - inputs do not satisfy circuit constraints"
    echo "=".repeat(60)
    echo ""
    echo "This is expected if your witness values don't satisfy the circuit."
    echo "For example, if the circuit requires a * b = 15, but you provided"
    echo "values that multiply to a different result."

{.pop.}

when isMainModule:
  main()
