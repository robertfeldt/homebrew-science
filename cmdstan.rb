class Cmdstan < Formula
  desc "Probabilistic programming language for Bayesian inference"
  homepage "http://mc-stan.org/"
  bottle do
    cellar :any
    sha256 "a6c23277dcc15ce6c70f3b50b7e3cdc749d0b83139fb7de270e36564a70a6460" => :yosemite
    sha256 "0fac67e14fb25191104c09df25ca437d891104925f56aa307b0e650dc7d07b96" => :mavericks
    sha256 "336473380148fd20886c8fcb68538a4cbc77daa52c1a515d5bcb3f4793cfe1db" => :mountain_lion
  end

  # tag "math"

  url "https://github.com/stan-dev/cmdstan/releases/download/v2.9.0/cmdstan-2.9.0.tar.gz"
  sha256 "a9f2858caa5b55576da85ef31b4eae632c97837aa042514242a9aad7ada97121"

  depends_on "boost"
  depends_on "eigen"

  def install
    system "make", "build"

    # symlink the two commands
    bin.install "bin/stansummary" 
    bin.install "bin/stanc"

    # But we need more from the bin dir...
    bin.install Dir["bin/*"] # This copies over all of the rest of the bin dir but also symlinks ;)
	
    doc.install "CONTRIBUTING.md", "LICENSE", "README.md"

    # For the standard stan make system to work we need the following files in prefix:
    prefix.install "src", "makefile", "make", "stan_2.9.0", "examples"

	  (include/"stan").install Dir["stan_2.9.0/lib/stan_math_*/stan/*"]
  end

  test do
    system "#{bin}/stanc", "--version"
    cp doc/"examples/bernoulli/bernoulli.stan", "."
    system "#{bin}/stanc", "bernoulli.stan"
    system "make", "bernoulli_model.o", "CPPFLAGS=-I#{Formula["eigen"].include/"eigen3"}"
  end
end
