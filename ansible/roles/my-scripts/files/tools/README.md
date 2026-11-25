# Compiled helper tools

Each subdirectory here is the **source** of one compiled tool. The `my-scripts` role builds every one of them on
the target machine and installs the result to `~/.local/scripts/<directory name>`, where the `my-scripts` CLI picks
it up as `my-scripts <directory name>`.

Compiled binaries are platform specific (macOS arm64, Linux amd64, ...), so they are **never committed**. Only
source lives here.

## Adding a tool

1. Create `files/tools/<name>/` containing either
   - a Go module (`go.mod`, built with `go build`), or
   - a Rust crate (`Cargo.toml`, built with `cargo build --release`). The package name must equal `<name>`.
2. Optionally add a one-line `DESCRIPTION` file. It is installed as `~/.local/scripts/<name>.desc` and shown in
   `my-scripts --help`. A binary cannot carry an `@description:` comment, so without this file it shows "No
   description available."
3. Run `ansible-playbook --connection=local --inventory 127.0.0.1, --tags tools index.yaml` from `ansible/`, or
   re-run the playbook.

## Behaviour worth knowing

- A tool whose toolchain is missing (no `go`, no `cargo`) is skipped with a message rather than failing the play.
  A tool that fails to compile does fail it.
- Removing a tool from this directory does not remove its installed binary. Delete
  `~/.local/scripts/<name>` and `<name>.desc` by hand.
- Directories without a `go.mod` or `Cargo.toml` are skipped.
