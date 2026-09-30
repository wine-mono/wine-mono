# Managed RegAsm frontend

This tool calls `RegistrationServices` to register or unregister managed COM
types. It requires the implementation proposed in
[mono/mono#36](https://github.com/wine-mono/mono/pull/36).

Supported switches are `/codebase`, `/unregister`, `/silent`, `/nologo`, and
`/help` (also `/?`). Names are case insensitive and accept unambiguous prefixes.
Unsupported type-library and registry-file operations fail rather than report
success. Errors return 100; successful operations, including assemblies with
no registrable types, return zero. This is not a complete Microsoft RegAsm
implementation. Callback and registry failures can leave partial changes.

## CLI tests

Run `make check-regasm` in a configured Wine Mono build tree, or compile manually:

Build the frontend and a fixture without COM-visible types:

```sh
mcs -out:/tmp/regasm.exe tools/regasm/regasm.cs
mcs -target:library -out:/tmp/regasm-empty.dll tools/regasm/empty-assembly.cs
python3 tools/regasm/test-cli.py --assembly /tmp/regasm-empty.dll -- mono /tmp/regasm.exe
```

On Windows, compile with the .NET Framework C# compiler and omit `mono` from
the test command. Under Wine, use `wine` instead, with a disposable prefix
configured for a Wine Mono runtime containing the registration implementation.

These tests exercise argument parsing, exit status, diagnostics, and the
no-registrable-types path. They do not test registry writes or COM activation;
registration/callback/unregistration tests must be run separately.
