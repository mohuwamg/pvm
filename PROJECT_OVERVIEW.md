# pvm 项目概述

## 项目简介

**pvm (Pod Version Manager)** 是一个命令行工具，用于管理多个 CocoaPods 版本。该项目受到 [nvm (Node Version Manager)](https://github.com/nvm-sh/nvm) 的启发，采用相似的设计理念和实现方式，为 iOS 和 macOS 开发者提供便捷的 CocoaPods 版本管理解决方案。

## 项目背景

在 iOS 和 macOS 开发中，CocoaPods 是最流行的依赖管理工具之一。然而，不同项目可能需要不同版本的 CocoaPods，传统的全局安装方式只能保留一个版本，这给多项目开发带来了不便。开发者经常需要在不同版本之间切换，传统方法需要频繁卸载和重装，过程繁琐且容易出错。

pvm 通过提供版本隔离和快速切换功能，解决了这一痛点。开发者可以在同一台机器上安装多个 CocoaPods 版本，并根据项目需求快速切换，无需卸载和重装。

## 核心特性

pvm 提供了以下核心特性，使得 CocoaPods 版本管理变得简单高效：

**多版本管理**：支持在同一台机器上安装和管理多个 CocoaPods 版本，每个版本拥有独立的 gem 环境，互不干扰。

**快速版本切换**：通过简单的命令即可在不同版本之间切换，切换操作立即生效，无需重启终端或重新登录。

**项目级版本控制**：支持 `.pvmrc` 文件，允许在项目中指定所需的 CocoaPods 版本，确保团队成员使用一致的环境。

**版本别名**：支持为版本设置别名，方便记忆和使用，例如将 `1.12.0` 设置为 `stable`。

**命令补全**：提供 bash 和 zsh 的命令补全功能，提升用户体验。

**镜像源支持**：支持配置 RubyGems 镜像源，加速国内用户的下载速度。

**POSIX 兼容**：使用 POSIX 兼容的 shell 脚本实现，支持多种 shell 环境（bash、zsh、ksh 等）。

## 技术架构

pvm 的技术架构借鉴了 nvm 的设计思路，采用 shell 脚本实现，通过修改环境变量来实现版本切换。

### 目录结构

pvm 将所有数据存储在用户目录下的 `.pvm` 文件夹中，主要包含以下结构：

```
~/.pvm/
├── versions/
│   └── cocoapods/
│       ├── 1.11.0/
│       ├── 1.12.0/
│       └── 1.13.0/
├── alias/
│   ├── stable -> 1.12.0
│   └── latest -> 1.13.0
├── pvm.sh
└── bash_completion
```

**versions/cocoapods/**：存储所有已安装的 CocoaPods 版本，每个版本拥有独立的 gem 环境，包含 `bin/`、`gems/` 和 `specifications/` 目录。

**alias/**：存储版本别名，每个别名文件包含对应的版本号。

**pvm.sh**：核心脚本文件，包含所有 pvm 命令的实现。

**bash_completion**：命令补全脚本，提供命令、版本号和别名的自动补全。

### 工作原理

pvm 通过修改以下环境变量来实现版本切换：

**GEM_HOME**：设置为 `~/.pvm/versions/cocoapods/<version>`，指定 gem 的安装目录。这确保了每个 CocoaPods 版本使用独立的 gem 环境。

**GEM_PATH**：包含当前版本的 gem 路径，用于 gem 查找。

**PATH**：将 `$GEM_HOME/bin` 添加到 PATH 开头，确保 `pod` 命令指向正确版本的 CocoaPods。

**PVM_COCOAPODS_VERSION**：记录当前使用的 CocoaPods 版本号，用于状态跟踪。

当执行 `pvm use <version>` 时，pvm 会更新这些环境变量，使得后续的 `pod` 命令调用正确版本的 CocoaPods。由于环境变量的修改只影响当前 shell 会话，因此 pvm 必须作为 shell 函数实现，而非独立的可执行文件。

### 核心函数

pvm.sh 包含以下核心函数：

**pvm_install()**：安装指定版本的 CocoaPods。该函数会创建独立的 gem 环境，设置 GEM_HOME，然后使用 `gem install cocoapods -v <version>` 安装 CocoaPods 及其依赖。

**pvm_use()**：切换到指定版本的 CocoaPods。该函数会检查版本是否已安装，然后更新环境变量，并验证切换是否成功。

**pvm_ls()**：列出所有已安装的版本，并标记当前使用的版本。

**pvm_ls_remote()**：通过 `gem search` 命令查询 RubyGems 上所有可用的 CocoaPods 版本。

**pvm_uninstall()**：卸载指定版本，删除对应的 gem 环境目录。该函数会检查是否正在卸载当前使用的版本，如果是则拒绝操作。

**pvm_alias()** 和 **pvm_unalias()**：管理版本别名，允许用户为版本设置易记的名称。

**pvm_which()**：显示指定版本的 `pod` 命令路径。

**pvm_version()** 和 **pvm_resolve_alias()**：解析版本号和别名，支持别名到版本号的转换。

## 与 nvm 的对比

pvm 在设计上借鉴了 nvm 的许多优秀理念，但也针对 CocoaPods 的特点进行了调整。

| 特性 | nvm | pvm |
|------|-----|-----|
| 管理对象 | Node.js | CocoaPods |
| 实现语言 | Shell 脚本 | Shell 脚本 |
| 环境隔离方式 | PATH 切换 | GEM_HOME + PATH 切换 |
| 配置文件 | .nvmrc | .pvmrc |
| 版本别名 | 支持 | 支持 |
| 命令补全 | 支持 | 支持 |
| 远程版本列表 | 从 Node.js 官网获取 | 从 RubyGems 获取 |
| LTS 支持 | 支持 | 不支持（CocoaPods 无 LTS） |
| 默认包安装 | 支持 | 不支持 |

主要区别在于环境隔离方式。Node.js 是独立的二进制程序，nvm 只需修改 PATH 即可切换版本。而 CocoaPods 是 Ruby gem，需要通过 GEM_HOME 和 GEM_PATH 来隔离不同版本的 gem 环境。

## 项目文件说明

| 文件 | 说明 |
|------|------|
| `pvm.sh` | 核心脚本文件，包含所有 pvm 命令的实现 |
| `install.sh` | 安装脚本，用于自动安装和配置 pvm |
| `bash_completion` | 命令补全脚本，提供 bash 和 zsh 的自动补全功能 |
| `README.md` | 项目说明文档，包含安装和使用指南 |
| `EXAMPLES.md` | 详细的使用示例和最佳实践 |
| `LICENSE` | MIT 许可证文件 |
| `.gitignore` | Git 忽略文件配置 |

## 使用场景

pvm 适用于以下场景：

**多项目开发**：当您同时维护多个项目，每个项目使用不同版本的 CocoaPods 时，pvm 可以让您轻松在版本之间切换。

**版本兼容性测试**：当 CocoaPods 发布新版本时，您可以先在测试环境中安装并验证兼容性，而不影响现有项目。

**团队协作**：通过在项目中提交 `.pvmrc` 文件，确保所有团队成员使用相同的 CocoaPods 版本，避免因版本差异导致的构建问题。

**CI/CD 环境**：在持续集成和持续部署环境中，可以使用 pvm 快速安装和切换到项目所需的 CocoaPods 版本。

## 系统要求

pvm 需要以下系统环境：

- **操作系统**：macOS 10.12+ 或 Linux（Ubuntu、CentOS 等）
- **Shell**：bash 3.2+、zsh 5.0+ 或其他 POSIX 兼容的 shell
- **Ruby**：2.6.0+（CocoaPods 的依赖要求）
- **Git**：用于安装 pvm（如果使用安装脚本）

## 安装方式

pvm 提供两种安装方式：

**通过安装脚本**：使用 curl 或 wget 下载并运行安装脚本，自动完成安装和配置。

```bash
curl -o- https://github.com/mohuwamg/pvm/main/install.sh | bash
```

**手动安装**：克隆 pvm 仓库到本地，然后在 shell 配置文件中添加 source 命令。

```bash
git clone https://github.com/mohuwamg/pvm.git ~/.pvm
echo 'export PVM_DIR="$HOME/.pvm"' >> ~/.bashrc
echo '[ -s "$PVM_DIR/pvm.sh" ] && \. "$PVM_DIR/pvm.sh"' >> ~/.bashrc
source ~/.bashrc
```

## 未来规划

pvm 目前实现了核心功能，未来可能会添加以下增强功能：

**自动版本切换钩子**：集成到 shell 的 `cd` 命令中，自动检测 `.pvmrc` 文件并切换版本，无需手动执行 `pvm use`。

**版本锁定文件**：类似 `package-lock.json`，生成版本锁定文件，确保团队环境完全一致。

**插件系统**：允许第三方开发者扩展 pvm 功能，例如添加自定义命令或集成其他工具。

**性能优化**：缓存远程版本列表，减少网络请求，提升命令执行速度。

**GUI 工具**：提供图形界面版本管理工具，方便不熟悉命令行的用户使用。

**多平台支持**：扩展对 Windows（通过 WSL 或 Git Bash）的支持。

## 贡献指南

pvm 是一个开源项目，欢迎社区贡献。如果您发现 bug、有功能建议或想要贡献代码，请通过以下方式参与：

**提交 Issue**：在 GitHub 仓库中提交 issue，描述您遇到的问题或建议。

**提交 Pull Request**：Fork 项目，创建新分支，实现您的功能或修复，然后提交 pull request。

**改进文档**：帮助改进文档，修正错误或添加更多示例。

**分享经验**：在社区中分享您使用 pvm 的经验和最佳实践。

## 许可证

pvm 使用 MIT 许可证发布，允许自由使用、修改和分发。详见 [LICENSE](LICENSE) 文件。

## 致谢

pvm 的设计和实现受到 [nvm](https://github.com/nvm-sh/nvm) 项目的启发，感谢 nvm 团队为开源社区做出的贡献。同时感谢所有为 pvm 项目贡献代码、提出建议和报告问题的开发者。
