# typed: false
# frozen_string_literal: true

class Gtdo < Formula
  desc "Go port of the todo.txt-cli command-line interface"
  homepage "https://github.com/guerrero/gtdo-cli"
  license "MIT"

  on_macos do
    if Hardware::CPU.intel?
      url "https://github.com/guerrero/gtdo-cli/releases/download/v0.1.0/gtdo_0.1.0_darwin_amd64.tar.gz"
      sha256 "eabb0cbb26cbd5713f7ebd480fba56eea48b16d7c8ecc680438daa1845d53747"
    end
    if Hardware::CPU.arm?
      url "https://github.com/guerrero/gtdo-cli/releases/download/v0.1.0/gtdo_0.1.0_darwin_arm64.tar.gz"
      sha256 "293d2225a5432625adff91e8b4187a7e2a0569cbcb1e80109acd02035e997d17"
    end
  end

  on_linux do
    if Hardware::CPU.intel? && Hardware::CPU.is_64_bit?
      url "https://github.com/guerrero/gtdo-cli/releases/download/v0.1.0/gtdo_0.1.0_linux_amd64.tar.gz"
      sha256 "d0da9c49cb4acfd5cf08475d6de1adcf40de9678510c323633e41ac269761217"
    end
    if Hardware::CPU.arm? && Hardware::CPU.is_64_bit?
      url "https://github.com/guerrero/gtdo-cli/releases/download/v0.1.0/gtdo_0.1.0_linux_arm64.tar.gz"
      sha256 "4236aa7d3ff802ef827f61e15e709999b02590d3ad7eefd5fde939ca59c00f1b"
    end
  end

  def install
    bin.install "gtdo"
  end

  test do
    system bin/"gtdo", "-V"
  end
end
