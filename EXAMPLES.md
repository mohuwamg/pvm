# pvm 使用示例

本文档提供了 pvm (Pod Version Manager) 的详细使用示例，帮助您快速上手。

## 基础使用

### 安装 CocoaPods 版本

安装特定版本的 CocoaPods 非常简单，只需指定版本号即可。pvm 会自动下载并安装该版本到独立的环境中。

```bash
# 安装 CocoaPods 1.12.0
pvm install 1.12.0

# 安装最新版本
pvm install latest
```

安装过程中，pvm 会创建独立的 gem 环境，确保不同版本之间互不干扰。

### 切换 CocoaPods 版本

安装完成后，您可以使用 `pvm use` 命令切换到指定版本。切换操作会立即生效，影响当前 shell 会话。

```bash
# 切换到 1.12.0 版本
pvm use 1.12.0

# 验证当前版本
pod --version
# 输出: 1.12.0
```

### 查看已安装的版本

使用 `pvm ls` 命令可以查看所有已安装的 CocoaPods 版本，当前使用的版本会用星号标记。

```bash
pvm ls
```

输出示例：

```
Installed CocoaPods versions:
  1.11.0
* 1.12.0 (currently using)
  1.13.0
```

### 查看可用的远程版本

如果您想知道 RubyGems 上有哪些 CocoaPods 版本可供安装，可以使用 `pvm ls-remote` 命令。

```bash
pvm ls-remote
```

该命令会列出所有可用版本，按版本号降序排列。

### 卸载版本

当您不再需要某个版本时，可以使用 `pvm uninstall` 命令将其卸载，释放磁盘空间。

```bash
# 卸载 1.11.0 版本
pvm uninstall 1.11.0
```

注意：您无法卸载当前正在使用的版本，需要先切换到其他版本。

## 高级功能

### 使用版本别名

版本别名可以让您为特定版本设置易记的名称，方便团队协作和版本管理。

```bash
# 为 1.12.0 创建别名 'stable'
pvm alias stable 1.12.0

# 使用别名切换版本
pvm use stable

# 查看当前版本
pvm current
# 输出: 1.12.0

# 删除别名
pvm unalias stable
```

常见的别名使用场景包括：

- `stable` - 指向团队当前使用的稳定版本
- `latest` - 指向最新的发布版本
- `project-a` - 指向特定项目使用的版本

### 使用 .pvmrc 文件

`.pvmrc` 文件允许您在项目中指定所需的 CocoaPods 版本，确保团队成员使用相同的版本。

**创建 .pvmrc 文件：**

在项目根目录创建 `.pvmrc` 文件，内容为版本号：

```bash
echo "1.12.0" > .pvmrc
```

**使用 .pvmrc 文件：**

进入项目目录后，运行 `pvm use` 命令（不带参数），pvm 会自动读取 `.pvmrc` 文件并切换到指定版本。

```bash
cd /path/to/your/project
pvm use
# 输出: Now using CocoaPods 1.12.0
```

**自动切换版本：**

您可以在 shell 配置文件（`~/.bashrc` 或 `~/.zshrc`）中添加以下代码，实现自动版本切换：

```bash
cd_with_pvm() {
  builtin cd "$@" || return
  if [ -f .pvmrc ]; then
    pvm use
  fi
}
alias cd='cd_with_pvm'
```

添加后，每次 `cd` 进入包含 `.pvmrc` 的目录时，pvm 会自动切换到指定版本。

### 查看版本路径

使用 `pvm which` 命令可以查看特定版本的 `pod` 命令路径，这在调试或脚本编写时很有用。

```bash
# 查看当前版本的 pod 路径
pvm which

# 查看特定版本的 pod 路径
pvm which 1.12.0
# 输出: /home/user/.pvm/versions/cocoapods/1.12.0/bin/pod
```

### 使用镜像源加速下载

如果您在国内使用 pvm，可以通过设置 `PVM_RUBY_MIRROR` 环境变量来使用国内镜像源，加速 gem 的下载。

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
export PVM_RUBY_MIRROR=https://gems.ruby-china.com/

# 然后重新加载配置
source ~/.bashrc

# 安装时会自动使用镜像源
pvm install 1.12.0
```

## 实际应用场景

### 场景一：多项目版本管理

假设您同时维护两个项目，一个使用 CocoaPods 1.11.0，另一个使用 1.12.0。使用 pvm 可以轻松在两个版本之间切换。

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

### 场景二：测试新版本兼容性

当 CocoaPods 发布新版本时，您可以先在测试环境中安装并验证兼容性，而不影响现有项目。

```bash
# 安装最新版本
pvm install latest

# 切换到最新版本
pvm use latest

# 在测试项目中验证
cd ~/projects/test-project
pod install

# 如果有问题，立即切换回稳定版本
pvm use stable
```

### 场景三：团队协作

通过在项目中提交 `.pvmrc` 文件，确保所有团队成员使用相同的 CocoaPods 版本。

```bash
# 项目负责人设置版本
echo "1.12.0" > .pvmrc
git add .pvmrc
git commit -m "Add .pvmrc to specify CocoaPods version"
git push

# 团队成员拉取代码后
git pull
pvm use  # 自动切换到 1.12.0
pod install
```

## 常见问题

### 如何查看当前使用的版本？

```bash
pvm current
```

或者直接使用 CocoaPods 命令：

```bash
pod --version
```

### 如何更新 pvm 本身？

如果 pvm 有新版本发布，您可以通过重新运行安装脚本来更新：

```bash
curl -o- https://github.com/mohuwamg/pvm/main/install.sh | bash
```

### 如何完全卸载 pvm？

删除 pvm 目录和 shell 配置中的相关行：

```bash
# 删除 pvm 目录
rm -rf ~/.pvm

# 编辑 ~/.bashrc 或 ~/.zshrc，删除以下行：
# export PVM_DIR="$HOME/.pvm"
# [ -s "$PVM_DIR/pvm.sh" ] && \. "$PVM_DIR/pvm.sh"
# [ -s "$PVM_DIR/bash_completion" ] && \. "$PVM_DIR/bash_completion"
```

### pvm 与系统全局安装的 CocoaPods 冲突吗？

pvm 通过修改 `PATH` 和 `GEM_HOME` 环境变量来管理版本，优先级高于系统全局安装。当您使用 `pvm use` 后，`pod` 命令会指向 pvm 管理的版本。如果您想使用系统全局版本，可以不运行 `pvm use`，或者在新的 shell 会话中使用。

## 最佳实践

**在项目中使用 .pvmrc 文件**：始终在项目根目录创建 `.pvmrc` 文件，明确指定所需的 CocoaPods 版本，避免团队成员因版本不一致导致的问题。

**使用别名管理常用版本**：为常用版本创建别名，如 `stable`、`dev`，方便快速切换。

**定期清理不用的版本**：使用 `pvm ls` 查看已安装的版本，使用 `pvm uninstall` 卸载不再使用的版本，释放磁盘空间。

**配置镜像源**：如果您在国内，建议配置 `PVM_RUBY_MIRROR` 环境变量，使用国内镜像源加速下载。

**自动化版本切换**：在 shell 配置中添加自动切换钩子，进入项目目录时自动切换到 `.pvmrc` 指定的版本。
