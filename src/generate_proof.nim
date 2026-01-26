## Generate and validate Groth16 proof programmatically

{.push raises: [CatchableError].}

import std/[strutils, os]
import taskpools
import groth16/prover
import groth16/verifier
import groth16/fake_setup
import groth16/zkey_types
import groth16/files/r1cs
import groth16/files/witness
import groth16/bn128/fields

proc main() {.raises: [CatchableError].} =
  if paramCount() < 2:
    echo "Usage: ", getAppFilename(), " <a> <b>"
    echo "  where a * b = 15"
    quit(1)
  
  var a: int
  var b: int
  
  try:
    a = parseInt(paramStr(1))
  except ValueError:
    echo "Error: invalid value for a: ", paramStr(1)
    quit(1)
  
  try:
    b = parseInt(paramStr(2))
  except ValueError:
    echo "Error: invalid value for b: ", paramStr(2)
    quit(1)
  
  let c = a * b
  
  if c != 15:
    echo "Error: a * b = ", c, " but circuit requires a * b = 15"
    quit(1)
  
  echo "=".repeat(60)
  echo "Generate and Validate Groth16 Proof"
  echo "=".repeat(60)
  echo ""
  
  const witnessCfg = WitnessConfig(
    nWires: 4,
    nPubOut: 1,
    nPubIn: 0,
    nPrivIn: 2,
    nLabels: 0
  )
  
  const constraint1: Constraint = (
    A: @[(wireIdx: 2, value: oneFr)],
    B: @[(wireIdx: 3, value: oneFr)],
    C: @[(wireIdx: 1, value: oneFr)]
  )
  
  let fifteen = intToFr(15)
  let minus15 = negFr(fifteen)
  let constraint2: Constraint = (
    A: @[],
    B: @[],
    C: @[(wireIdx: 1, value: oneFr), (wireIdx: 0, value: minus15)]
  )
  
  let constraints = @[constraint1, constraint2]
  
  let r1cs = R1CS(
    r: primeR,
    cfg: witnessCfg,
    nConstr: constraints.len,
    constraints: constraints,
    wireToLabel: @[]
  )
  
  echo "[1/4] Creating R1CS circuit programmatically..."
  echo "      Circuit: prove you know factors a and b such that a * b = 15"
  echo "      Constraints: ", r1cs.nConstr
  echo ""
  
  let witnessValues = @[
    intToFr(1),
    intToFr(c),
    intToFr(a),
    intToFr(b)
  ]
  
  let witness = Witness(
    curve: "bn128",
    r: primeR,
    nvars: witnessValues.len,
    values: witnessValues
  )
  
  echo "[2/4] Creating witness programmatically..."
  echo "      Inputs: a = ", a, ", b = ", b
  echo "      Output: c = ", c
  echo ""
  
  echo "[3/4] Performing fake trusted setup..."
  let zkey = createFakeCircuitSetup(r1cs, flavour=Snarkjs)
  echo "      ✓ Trusted setup complete"
  echo ""
  
  echo "[4/4] Generating and verifying proof..."
  var pool = Taskpool.new()
  let proof = generateProof(zkey, witness, pool)
  pool.shutdown()
  
  let vkey = extractVKey(zkey)
  let isValid = verifyProof(vkey, proof)
  
  if isValid:
    echo "      ✓ Proof verification: SUCCESS"
    echo ""
    echo "=".repeat(60)
    echo "Proof is valid!"
    echo "=".repeat(60)
    echo ""
    echo "Successfully proved knowledge of factors ", a, " and ", b, " such that ", a, " * ", b, " = ", c
    quit(0)
  else:
    echo "      ✗ Proof verification: FAILED"
    echo ""
    echo "=".repeat(60)
    echo "Proof verification failed"
    echo "=".repeat(60)
    quit(1)

{.pop.}

when isMainModule:
  main()
