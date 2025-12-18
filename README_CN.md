# pvm (Pod Version Manager)

`pvm` 是一个命令行工具，用于安装和管理多个 CocoaPods 版本。它的灵感来自 [nvm](https://github.com/nvm-sh/nvm)，提供了一种简单的方式来在不同的 CocoaPods 版本之间切换。

## 安装

要安装或更新 `pvm`，可以使用 `install.sh` 脚本：

```bash
# 使用 curl
curl -o- https://raw.githubusercontent.com/mohuwamg/pvm/main/install.sh | bash

# 使用 wget
wget -qO- https://raw.githubusercontent.com/mohuwamg/pvm/main/install.sh | bash
```

这将把 `pvm` 仓库克隆到 `~/.pvm`，并将必要的 source 行添加到您的 shell 配置文件（`~/.bashrc`、`~/.zshrc` 或 `~/.profile`）中。

安装完成后，您需要重启 shell 或运行以下命令使更改生效：

```bash
source ~/.bashrc  # 或 ~/.zshrc、~/.profile
```

## 快速开始

安装 `pvm` 后，您可以开始使用它来管理 CocoaPods 版本。

**1. 安装 CocoaPods 版本：**

```bash
pvm install 1.12.0
```

这将下载并安装 CocoaPods 1.12.0 到独立的环境中。

**2. 使用特定版本：**

```bash
pvm use 1.12.0
```

这将把当前 shell 切换到指定版本的 CocoaPods。

**3. 验证版本：**

```bash
pod --version
# 输出: 1.12.0
```

## 命令

`pvm` 提供了一组命令来管理您的 CocoaPods 版本：

| 命令 | 说明 |
|---|---|
| `pvm install <version>` | 安装指定版本的 CocoaPods。使用 `latest` 安装最新版本。 |
| `pvm use <version>` | 在当前 shell 中切换到指定版本的 CocoaPods。 |
| `pvm ls` | 列出所有已安装的 CocoaPods 版本。 |
| `pvm ls-remote` | 列出 RubyGems 上所有可用的 CocoaPods 版本。 |
| `pvm uninstall <version>` | 卸载指定版本的 CocoaPods。 |
| `pvm current` | 显示当前使用的 CocoaPods 版本。 |
| `pvm alias <name> <version>` | 为特定版本创建别名。 |
| `pvm unalias <name>` | 删除别名。 |
| `pvm which [version]` | 显示指定版本的 `pod` 二进制文件路径。 |
| `pvm unload` | 卸载 pvm 环境并使用系统 CocoaPods。 |
| `pvm --help` | 显示帮助信息。 |

## `.pvmrc` 文件

`pvm` 支持 `.pvmrc` 文件来自动切换版本。如果您的项目根目录有 `.pvmrc` 文件，您可以运行 `pvm use` 而不指定版本，`pvm` 将自动切换到文件中指定的版本。

**示例 `.pvmrc` 文件：**

```
1.12.0
```

要在 `cd` 进入包含 `.pvmrc` 文件的目录时启用自动切换，您可以将以下内容添加到您的 shell 配置文件中：

```bash
cd_with_pvm() {
  cd "$@" || return
  if [ -f .pvmrc ]; then
    pvm use
  fi
}
alias cd='cd_with_pvm'
```

## 环境变量

- `PVM_DIR`：`pvm` 的安装目录。默认为 `~/.pvm`。
- `PVM_RUBY_MIRROR`：用于加速下载的 RubyGems 镜像。例如，`https://gems.ruby-china.com/`。

## 卸载
要卸载 `pvm`，您可以运行以下命令：

```bash
curl -o- https://raw.githubusercontent.com/mohuwamg/pvm/main/uninstall.sh | bash
```

或者，如果您已经克隆了仓库，可以运行：

```bash
./uninstall.sh
```

这将删除 `~/.pvm` 目录，并从您的 shell 配置文件中移除 `pvm` 配置。

## 使用示例

### 多项目版本管理

```bash
# 项目 A 使用 1.11.0
cd ~/projects/project-a
echo "1.11.0" > .pvmrc
pvm use
pod install

# 项目 B 使用 1.12.0
cd ~/projects/project-b
echo "1.12.0" > .pvmrc
pvm use
pod install
```

### 使用版本别名

```bash
# 为 1.12.0 创建别名 'stable'
pvm alias stable 1.12.0

# 使用别名切换版本
pvm use stable

# 删除别名
pvm unalias stable
```

### 配置国内镜像源

在 `~/.bashrc` 或 `~/.zshrc` 中添加：

```bash
export PVM_RUBY_MIRROR=https://gems.ruby-china.com/
```

然后重新加载配置：

```bash
source ~/.bashrc
```

## 贡献

欢迎贡献！请随时提交 pull request 或在 [GitHub 仓库](https://github.com/mohuwamg/pvm) 上提出 issue。

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 相关文档

- [快速开始指南](QUICKSTART.md)
- [详细使用示例](EXAMPLES.md)
- [项目概述](PROJECT_OVERVIEW.md)
### 通过 Homebrew 安装

```bash
brew install --formula https://raw.githubusercontent.com/mohuwamg/pvm/main/Formula/pvm.rb
```

安装后可直接运行 `pvm --help`，如需在 shell 会话中启用自动补全与持久化，可在配置文件中添加：

```bash
export PVM_DIR="$HOME/.pvm"
[ -s "$PVM_DIR/pvm.sh" ] && . "$PVM_DIR/pvm.sh"
[ -s "$PVM_DIR/bash_completion" ] && . "$PVM_DIR/bash_completion"
```
