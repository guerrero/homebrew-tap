class WhjvenylFasd < Formula
  desc "Command-line productivity booster for quick file access"
  homepage "https://github.com/whjvenyl/fasd"
  url "https://github.com/whjvenyl/fasd/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "3de1116957fcbb38b31edaa36287532e51f209a1e6c5f44b7a12754540096f73"
  license "MIT"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  def install
    bin.install "fasd"
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/fasd --version").strip
  end
end
