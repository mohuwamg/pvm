_# pvm (Pod Version Manager)_

`pvm` is a command-line tool that allows you to install and manage multiple versions of CocoaPods. It is inspired by [nvm](https://github.com/nvm-sh/nvm) and provides a simple way to switch between different CocoaPods versions on a per-project basis.

## Installation

To install or update `pvm`, you can use the `install.sh` script:

```bash
# using curl
curl -o- https://raw.githubusercontent.com/mohuwamg/pvm/main/install.sh | bash

# using wget
wget -qO- https://raw.githubusercontent.com/mohuwamg/pvm/main/install.sh | bash
```

This will clone the `pvm` repository to `~/.pvm` and add the necessary source lines to your shell profile (`~/.bashrc`, `~/.zshrc`, or `~/.profile`).

After installation, you will need to restart your shell or run the following command for the changes to take effect:

```bash
source ~/.bashrc  # or ~/.zshrc, ~/.profile

### Homebrew

```bash
brew install --formula https://raw.githubusercontent.com/mohuwamg/pvm/main/Formula/pvm.rb
```

After installation, run `pvm --help`. To enable shell integration and completion, add:

```bash
export PVM_DIR="$HOME/.pvm"
[ -s "$PVM_DIR/pvm.sh" ] && . "$PVM_DIR/pvm.sh"
[ -s "$PVM_DIR/bash_completion" ] && . "$PVM_DIR/bash_completion"
```
```

## Getting Started

Once `pvm` is installed, you can start using it to manage your CocoaPods versions.

**1. Install a CocoaPods version:**

```bash
pvm install 1.12.0
```

This will download and install CocoaPods version 1.12.0 into its own isolated environment.

**2. Use a specific version:**

```bash
pvm use 1.12.0
```

This will switch your current shell to use the specified version of CocoaPods.

**3. Verify the version:**

```bash
pod --version
# Output: 1.12.0
```

## Commands

`pvm` provides a set of commands to manage your CocoaPods versions:

| Command | Description |
|---|---|
| `pvm install <version>` | Install a specific version of CocoaPods. Use `latest` for the newest version. |
| `pvm use <version>` | Switch to a specific version of CocoaPods in the current shell. |
| `pvm ls` | List all installed versions of CocoaPods. |
| `pvm ls-remote` | List all available versions of CocoaPods from RubyGems. |
| `pvm uninstall <version>` | Uninstall a specific version of CocoaPods. |
| `pvm current` | Display the currently active version of CocoaPods. |
| `pvm alias <name> <version>` | Create an alias for a specific version. |
| `pvm unalias <name>` | Remove an alias. |
| `pvm which [version]` | Display the path to the `pod` binary for a specific version. |
| `pvm --help` | Show the help message. |

## `.pvmrc` File

`pvm` supports `.pvmrc` files for automatic version switching. If you have a `.pvmrc` file in your project's root directory, you can run `pvm use` without specifying a version, and `pvm` will automatically switch to the version specified in the file.

**Example `.pvmrc` file:**

```
1.12.0
```

To enable automatic switching when you `cd` into a directory with a `.pvmrc` file, you can add the following to your shell profile:

```bash
cd_with_pvm() {
  cd "$@" || return
  if [ -f .pvmrc ]; then
    pvm use
  fi
}
alias cd='cd_with_pvm'
```

## Environment Variables

- `PVM_DIR`: The directory where `pvm` is installed. Defaults to `~/.pvm`.
- `PVM_RUBY_MIRROR`: The RubyGems mirror to use for faster downloads. For example, `https://gems.ruby-china.com/`.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue on the [GitHub repository](https://github.com/mohuwamg/pvm).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
