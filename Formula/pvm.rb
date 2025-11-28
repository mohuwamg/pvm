class Pvm < Formula
  desc "Pod Version Manager for CocoaPods"
  homepage "https://github.com/mohuwamg/pvm"
  license "MIT"
  head "https://github.com/mohuwamg/pvm.git", branch: "main"

  def install
    pkgshare.install "pvm.sh"
    bash_completion.install "bash_completion"
    (bin/"pvm").write <<~EOS
      #!/bin/bash
      source "#{pkgshare}/pvm.sh"
      pvm "$@"
    EOS
  end

  def caveats
    <<~EOS
      To enable shell integration, add:
        export PVM_DIR="$HOME/.pvm"
        [ -s "$PVM_DIR/pvm.sh" ] && . "$PVM_DIR/pvm.sh"
        [ -s "$PVM_DIR/bash_completion" ] && . "$PVM_DIR/bash_completion"
      Alternatively use the wrapper: #{HOMEBREW_PREFIX}/bin/pvm
    EOS
  end

  test do
    system "#{bin}/pvm", "--help"
  end
end
