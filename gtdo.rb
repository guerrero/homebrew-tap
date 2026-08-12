# typed: false
# frozen_string_literal: true

class Gtdo < Formula
  desc "Go port of the todo.txt-cli command-line interface"
  homepage "https://github.com/guerrero/gtdo-cli"
  license "MIT"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/guerrero/gtdo-cli/releases/download/v0.2.0/gtdo_0.2.0_darwin_amd64.tar.gz"
      sha256 "59d9585ec1c2ff1bd6c87c8f24c004a45ab760f9c64b1afc094f1f13968d187e"
    end
    if Hardware::CPU.arm?
      url "https://github.com/guerrero/gtdo-cli/releases/download/v0.2.0/gtdo_0.2.0_darwin_arm64.tar.gz"
      sha256 "1485c13d9df567eb4db50c276d7cb4fd8788ea628fb337e9a50f353a6f3b6f0c"
    end
  end

  on_linux do
    if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      url "https://github.com/guerrero/gtdo-cli/releases/download/v0.2.0/gtdo_0.2.0_linux_amd64.tar.gz"
      sha256 "e950a23517a92d89c062e2bad3ff9829f8334891c8ba24c2b3f1d211ff9ef36b"
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/guerrero/gtdo-cli/releases/download/v0.2.0/gtdo_0.2.0_linux_arm64.tar.gz"
      sha256 "b5a1392266627819cd034bb67471102f9eceeb9fdf81c40e559fd094ab5c1e6b"
    end
  end

  def install
    bin.install "gtdo"
  end

  test do
    system bin/"gtdo", "-V"
  end
end
