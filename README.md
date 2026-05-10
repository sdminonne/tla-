# TLA+ CLI

Command-line setup for [TLA+](https://lamport.azurewebsites.net/tla/tla.html) tools including TLC (model checker), SANY (parser), PlusCal translator, and the TLA+ REPL.

## Prerequisites

- Java >= 11
- Python 3
- `curl`

## Installation

```bash
make check-prereq   # verify java and python3 are available
make install         # download jars and create wrapper scripts
```

After installation, add the `bin/` directory to your PATH:

```bash
export PATH="$(pwd)/bin:$PATH"
```

## Available Commands

| Command    | Description                          |
|------------|--------------------------------------|
| `tlc`      | TLC model checker                    |
| `sany`     | TLA+ parser (syntax/semantic check)  |
| `pcal`     | PlusCal-to-TLA+ translator          |
| `tla2tex`  | TLA+ to LaTeX converter             |
| `tlcrepl`  | Interactive TLA+ REPL               |

## Tutorial: A Simple Counter

This walkthrough creates a minimal TLA+ spec, checks its syntax, and runs the model checker.

### 1. Write the spec

```bash
mkdir -p tutorial/counter && cd tutorial/counter

cat <<'EOF' > Counter.tla
---- MODULE Counter ----
EXTENDS Integers

VARIABLE count

Init == count = 0

Next == count' = count + 1

Spec == Init /\ [][Next]_count

TypeOK == count \in 0..10
====
EOF
```

This spec models a counter that starts at `0` and increments by `1` on every step. The `TypeOK` invariant asserts the counter stays in `0..10` — which TLC will eventually violate, producing a counterexample.

### 2. Parse the spec

```bash
sany Counter.tla
```

SANY checks syntax and semantic correctness. If there are no errors you'll see output ending with something like:

```
Semantic processing of module Counter
```

### 3. Create a model config

TLC needs a configuration file to know what to check.

```bash
cat <<'EOF' > Counter.cfg
SPECIFICATION Spec
INVARIANT TypeOK
EOF
```

### 4. Run the model checker

```bash
tlc Counter.tla
```

TLC will explore states and report a violation of `TypeOK` once `count` reaches `11`. The output includes a trace showing the sequence of states from `count = 0` to `count = 11`.

### 5. Fix the spec

To make the model pass, bound the counter so it wraps around:

```bash
cat <<'EOF' > Counter.tla
---- MODULE Counter ----
EXTENDS Integers

VARIABLE count

Init == count = 0

Next == count' = IF count < 10 THEN count + 1 ELSE 0

Spec == Init /\ [][Next]_count

TypeOK == count \in 0..10
====
EOF
```

Re-run TLC:

```bash
tlc Counter.tla
```

This time TLC finishes with no errors — all reachable states satisfy `TypeOK`.

## Tutorial: PlusCal

PlusCal is an algorithm language that compiles to TLA+. Here's a quick example.

### 1. Write a PlusCal algorithm

```bash
mkdir -p tutorial/euclidgcd && cd tutorial/euclidgcd

cat <<'EOF' > EuclidGCD.tla
---- MODULE EuclidGCD ----
EXTENDS Integers

CONSTANT M, N

(*--algorithm EuclidGCD
variables a = M, b = N;
begin
  while b /= 0 do
    if a > b then
      a := a - b;
    else
      b := b - a;
    end if;
  end while;
  assert a = 1;  \* will fail for inputs whose GCD /= 1
end algorithm;*)
====
EOF
```

### 2. Translate PlusCal to TLA+

```bash
pcal EuclidGCD.tla
```

This inserts the generated TLA+ translation directly into `EuclidGCD.tla` between special comment markers.

### 3. Create the config

```bash
cat <<'EOF' > EuclidGCD.cfg
SPECIFICATION Spec
CONSTANTS
  M = 12
  N = 8
EOF
```

### 4. Run TLC

```bash
tlc EuclidGCD.tla
```

Since `GCD(12, 8) = 4`, the `assert a = 1` will fail and TLC will produce a counterexample trace. Change the constants to `M = 7` and `N = 13` (coprime) and the assertion passes.

## Cleanup

```bash
make clean
```

## References

- [TLA+ GitHub repository](https://github.com/tlaplus/tlaplus)
- [Learn TLA+ — CLI usage](https://learntla.com/topics/cli.html)
- [TLA+ Community Modules](https://github.com/tlaplus/CommunityModules)
- [Leslie Lamport's TLA+ page](https://lamport.azurewebsites.net/tla/tla.html)
