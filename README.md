# PKG_NAME

A runnable Fin **library package starter**, with a small checked-add API showing
public imports, concrete return values, recoverable errors, and executable tests.
Replace the sample API with your package's functionality; this repository does
not install dependencies or implement another package manager.

Requires Fin 0.4.0 with its LLVM backend, the matching standard library, and a C
linker driver (`cc`, or `FIN_CC`). The local runner requires a POSIX shell and
`mktemp` (Linux/macOS/WSL). See the
[Fin agent guide](https://github.com/M1778/Fin/blob/master/docs/agent-guide.md).

## Run the unchanged starter

With `finc` on `PATH`, from the repository root:

```sh
sh tests/run.sh all -O0
sh tests/run.sh all -O2
```

`all` checks the library, tests, and example, then builds and **executes** both
the tests and example. Tests cover int32 extrema, overflow in both directions,
operand reversal, and all 40,401 pairs in `[-100, 100]`.

You can invoke the runner from any directory and pin a toolchain:

```sh
FINC=/absolute/path/to/finc \
FIN_LIBS=/absolute/path/to/lib/std \
sh /absolute/path/to/package/tests/run.sh all -O2
```

`FINC` is one executable path/name, not a command with flags. `FIN_LIBS`, when
set, is passed explicitly as `--fin-libs`; include the real standard-library
directory. Unset it to use the compiler's bundled library. An explicitly empty
value intentionally disables that fallback. Temporary outputs are removed on
success, failure, and normal termination signals; compiler/program exit codes
are preserved. No binaries or object files are left in the checkout.

Tasks are `check` (frontend only), `test`, `example`, and `all`. The optional
second argument is `-O0`, `-O1`, `-O2`, or `-O3` (default `-O0`).

If you use [finn](https://github.com/M1778/finn), equivalent manifest tasks are:

```sh
finn do check
finn do test -- -O2
finn do example
finn do verify -- -O2
```

Use `finn do test`, **not** `finn test`, to execute these assertions: the latter
currently only type-checks tests. `finn build` builds an executable, whereas this
package's entrypoint is a library without `main`; run the example task instead.
Dependencies belong in `[packages]` and are managed by finn. This dependency-free
starter's runner adds only `src` and the configured standard library to imports.

## Customize once

Use a unique Fin module identifier such as `safe_math`: letters, digits, and
underscores, beginning with a letter; avoid language keywords and standard-library
module names. This keeps package identity and import spelling simple.

1. Replace the literal text `PKG_NAME` with `safe_math` in these files:
   `src/PKG_NAME.fin`, `tests/test_PKG_NAME.fin`, `tests/run.sh`,
   `examples/basic.fin`, `finn.toml`, and `exports.fin`.
2. Rename the two files from the repository root:

   ```sh
   mv src/PKG_NAME.fin src/safe_math.fin
   mv tests/test_PKG_NAME.fin tests/test_safe_math.fin
   ```

3. Replace `{{DESCRIPTION}}` in the source comment with your description. Update
   this README's title, examples, and install URL for your package/repository.
   The final manifest must have `name = "safe_math"` and
   `entrypoint = "safe_math.fin"` (finn resolves entrypoints under `src/`).
4. Run `sh tests/run.sh all -O0` and `sh tests/run.sh all -O2` again. The runner
   references the renamed library and test, so stale placeholders fail visibly.

Keep `namespace fin` unchanged. Consumers then write
`import { AddResult, checked_add } from safe_math::fin;`.
`safe_math` is the filename/module, and `fin` is the declared namespace, **not**
a directory. Do not rename the module to the generic `lib`, which can collide
with other dependencies. Import symbols by name; module-qualified Fin function
calls still have backend limitations.

The checked-in CI workflow retains the raw starter filenames. After customization,
review/adapt its paths separately before relying on hosted CI; local verification
does not claim a hosted CI run.

## Public API

```fin
import { AddResult, checked_add } from PKG_NAME::fin;

fun main() <noret> {
    let sum <AddResult> = checked_add(20, 22);
    if (sum.ok) {
        printf("20 + 22 = %d\n", sum.value);
    }
    let overflow <AddResult> = checked_add(2147483647, 1);
    if (!overflow.ok) {
        printf("sum is outside the int32 range\n");
    }
}
```

`checked_add(a: int, b: int) <AddResult>` accepts any two signed 32-bit integers.
`AddResult` has public fields `ok <bool>` and `value <int>`:

- Success: `ok == true`, `value` is the exact mathematical sum.
- Overflow/underflow: `ok == false`, `value == 0`. Zero is a deterministic error
  value, **not** a successful sum; always check `ok` first.

The function checks against `2147483647` and `-2147483647 - 1` **before** adding.
It does not wrap, saturate, allocate, or abort. The minimum spelling avoids a
positive `2147483648` intermediate literal. The boolean status is deliberate:
this compiler rejects imported enum-valued struct fields and imported enum-member
casts during code generation. Generic `Result` is not needed here.

`exports.fin` is an honest, comment-only package-layout marker. Finn recognizes
its existence; it does not parse it as a re-export map. Actual public declarations
live in `src/PKG_NAME.fin`, and consumers import that module directly.

## Install your published package

After changing the owner/repository to your actual published package:

```sh
finn add YOUR_OWNER/PKG_NAME
```

The starter needs no third-party package to run. Dependency resolution,
installation, and registry operations remain finn's responsibility.

## License

MIT
