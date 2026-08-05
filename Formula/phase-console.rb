class PhaseConsole < Formula
  desc "Local web console for the phased-execution Claude Code skill"
  homepage "https://github.com/zsarir/phased-execution"
  url "https://registry.npmjs.org/phase-console/-/phase-console-1.0.1.tgz"
  # The shasum -a 256 of the tarball AS SERVED BY THE REGISTRY — never of a
  # locally packed one. The release workflow (or a hand-run of its curl) bumps it.
  sha256 "4d7ef5fbfc72b7a9199f0144e1b521c6469a8ac9564110cc74671e2e2260f306"
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
    # this install step cannot re-trigger it. `std_npm_args` is refused for the
    # same reason: it installs the CURRENT tree as a package, which re-packs it
    # and fires `prepack` — a client rebuild inside the sandbox, with no
    # devDependencies to do it with.
    libexec.install Dir["*"]
    cd libexec do
      system "npm", "install", "--omit=dev", "--no-audit", "--no-fund" # rubocop:disable FormulaAudit/StdNpmArgs
    end
    # An exec script rather than a symlink: it pins Homebrew's node, and hands
    # the shim the upgrade-stable opt_libexec path — so anything the console
    # writes down (launchd plists) survives `brew upgrade`'s Cellar rename.
    (bin/"phase-console").write <<~SH
      #!/bin/bash
      exec "#{formula_opt_bin("node")}/node" "#{opt_libexec}/bin/phase-console.mjs" "$@"
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
