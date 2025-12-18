class Pvm < Formula
  desc "Pod Version Manager for CocoaPods"
  homepage "https://github.com/mohuwamg/pvm"
  url "https://github.com/mohuwamg/pvm/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"
  head "https://github.com/mohuwamg/pvm.git", branch: "main"

  def install
    # Install the core script
    pkgshare.install "pvm.sh"
    pkgshare.install "bash_completion"
    
    # Create the binary wrapper
    (bin/"pvm").write <<~EOS
      #!/usr/bin/env bash
      export PVM_DIR="${HOME}/.pvm"
      [ -s "${PVM_DIR}/pvm.sh" ] && . "${PVM_DIR}/pvm.sh" || . "#{pkgshare}/pvm.sh"
      pvm "$@"
    EOS
  end

  def caveats
    <<~EOS
      To enable pvm in your shell, add the following to your .bashrc or .zshrc:
      
        export PVM_DIR="$HOME/.pvm"
        [ -s "#{opt_pkgshare}/pvm.sh" ] && . "#{opt_pkgshare}/pvm.sh"
        [ -s "#{opt_pkgshare}/bash_completion" ] && . "#{opt_pkgshare}/bash_completion"
        
      The 'pvm' command is also available as a standalone binary, but for full functionality 
      (like changing shell environment variables), sourcing the script is recommended.
    EOS
  end

  test do
    system "#{bin}/pvm", "--help"
  end
end
