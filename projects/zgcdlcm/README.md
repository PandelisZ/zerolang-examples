# Zero CLI

This project was created with `zero new cli`.

Try:

```sh
zero check .
zero test .
zero run .
zero dev --json .
zero build --target linux-musl-x64 --out .zero/out/app .
zero ship --target linux-musl-x64 --out .zero/ship/app .
```

The entry point receives `World` explicitly, so I/O is visible in the function signature. The generated output is deterministic and the manifest records the default release target.
