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

    # symlink the two commands. These are the only ones that should be symlinked to main bin dir.
    bin.install "bin/stansummary"
    bin.install "bin/stanc"

    # But unfortunately we need more from the bin dir since cmdstan uses the makefile
    # in the prefix dir when building executables for each new stan model. In order for that
    # makefiel to work it needs the object files that the cmdstan currently saves in the bin dir.
    # This makes it hard to change the structure of these files unless other tools that depend on
    # cmdstan also change. The print file that is copied
    #bin.install "bin/libstanc.a"
    #(bin/"cmdstan").install Dir["bin/cmdstan/*"]
    #(bin/"stan").install Dir["bin/stan/*"]

    # If we change the makefile we can move the files that cmdstan normally installs to bin in lib.
    # This was recommended by the homebrew-science maintainers as the preferred way since homebrew
    # do not want non-executable files installed into bin.
    lib.install "bin/libstanc.a"
    (lib/"cmdstan").install Dir["bin/cmdstan/*"]
    (lib/"stan").install Dir["bin/stan/*"]

    # We need to change make/command file so that lines with "bin/cmdstand" instead uses
    # "lib/cmdstan" and that the libstanc.a library has a lib instead of a bin path:
    inreplace "make/command" do |s|
      s.gsub! "bin/cmdstan/", "lib/cmdstan/"
      s.gsub! "bin/libstanc.a", "lib/libstanc.a"
    end

    # We need to change make/libstan so that libstanc.a is referred to via a lib path instead of a
    # bin path:
    inreplace "make/libstan" do |s|
      s.gsub! "bin/libstanc.a", "lib/libstanc.a"
      s.gsub! "bin/stan/%.o", "lib/stan/%.o"
      s.gsub! "src/%.cpp=bin/%.o", "src/%.cpp=lib/%.o"
    end

    # Several corresponding changes in the main makefile:
    inreplace "makefile" do |s|
      s.gsub! "LDLIBS_STANC = -Lbin", "LDLIBS_STANC = -Llib"
      s.gsub! "bin/%.o", "lib/%.o"
      s.gsub! "bin/stan/%.o :", "lib/stan/%.o :"
      s.gsub! "bin/libstanc.a", "lib/libstanc.a"
      s.gsub! "bin/%.d", "lib/%.d"
    end

    # Install docs
    doc.install "CONTRIBUTING.md", "LICENSE", "README.md"

    # For the standard stan make system to work we need the following files in prefix:
    prefix.install "src", "makefile", "make", "stan_2.9.0", "examples"

    # This cannot be done after the prefix.install of "stan_2.9.0" since the files are no longer around...
    # (include/"stan").install Dir["stan_2.9.0/lib/stan_math_*/stan/*"]
  end

  test do
    system "#{bin}/stanc", "--version"
    cp doc/"examples/bernoulli/bernoulli.stan", "."
    system "#{bin}/stanc", "bernoulli.stan"
    system "make", "bernoulli_model.o", "CPPFLAGS=-I#{Formula["eigen"].include/"eigen3"}"
  end
end
