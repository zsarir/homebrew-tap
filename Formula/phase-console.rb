class PhaseConsole < Formula
  desc "Local web console for the phased-execution Claude Code skill"
  homepage "https://github.com/zsarir/phased-execution"
  url "https://registry.npmjs.org/phase-console/-/phase-console-1.0.0.tgz"
  # Replaced by the release workflow (or by hand) with the shasum -a 256 of the
  # tarball AS SERVED BY THE REGISTRY — never of a locally packed one.
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"

  livecheck do
    url "https://registry.npmjs.org/phase-console/latest"
    strategy :json do |json|
      json["version"]
    end
  end

  depends_on "node"

  def install
    # The tarball ships the whole skill tree with the client prebuilt and the
    # server pre-stripped to .js. `npm install --omit=dev` resolves only the
    # two optionalDependencies (node-pty, ws); if the native build is skipped,
    # the console degrades honestly (no Terminal page) rather than failing.
    # NOTE: the package's build lives in `prepack`, not `prepare`, precisely so
    # this install step cannot re-trigger it.
    libexec.install Dir["*"]
    cd libexec do
      system "npm", "install", "--omit=dev", "--no-audit", "--no-fund"
    end
    # An exec script rather than a symlink: it pins Homebrew's node, and hands
    # the shim the upgrade-stable opt_libexec path — so anything the console
    # writes down (launchd plists) survives `brew upgrade`'s Cellar rename.
    (bin/"phase-console").write <<~SH
      #!/bin/bash
      exec "#{Formula["node"].opt_bin}/node" "#{opt_libexec}/bin/phase-console.mjs" "$@"
    SH
  end

  def caveats
    <<~EOS
      Point it at a repository that contains docs/plans:
        phase-console --root ~/code/your-repo

      The autopilot, agent sessions and the plan wizard need the `claude` CLI
      on PATH. If the Terminal page reports node-pty missing, its native build
      was skipped — everything else works without it.

      Running the background agent? After `brew upgrade phase-console`, run:
        phase-console --agent-restart
    EOS
  end

  test do
    assert_match "--root", shell_output("#{bin}/phase-console --help")
  end
end
