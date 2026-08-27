class PhaseConsole < Formula
  desc "Local web console for the phased-execution Claude Code skill"
  homepage "https://github.com/zsarir/phased-execution"
  url "https://registry.npmjs.org/phase-console/-/phase-console-3.3.0.tgz"
  # The shasum -a 256 of the tarball AS SERVED BY THE REGISTRY — never of a
  # locally packed one. The release workflow (or a hand-run of its curl) bumps it.
  sha256 "622d9545d5a94d6bb97b9f8ff7d1eed67df288ff3c0b5b3db24d8daafd0ec369"
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
    # server pre-stripped to .js, so this is a LOCAL install (prefix: false) in
    # libexec: it only resolves the two optionalDependencies (node-pty, ws).
    # The global form would re-pack the tree as a package instead — and the
    # package's build lives in `prepack` precisely so installs cannot fire it.
    # `--ignore-scripts` (part of std_npm_args) is fine: node-pty ships
    # prebuilds its loader resolves at require time, and if that native load
    # ever fails the console degrades honestly (no Terminal page) rather than
    # failing here.
    libexec.install Dir["*"]
    cd libexec do
      system "npm", "install", *std_npm_args(prefix: false), "--omit=dev"
      # std_npm_args ignores install scripts. macOS is covered by node-pty's
      # shipped prebuilds, but no Linux prebuilds exist — compile it here with
      # the host toolchain Homebrew/Linux already requires. Tolerated on
      # failure: without the native module the console runs and the Terminal
      # page degrades honestly.
      if OS.linux?
        begin
          system "npm", "rebuild", "node-pty"
        rescue BuildError
          opoo "node-pty did not compile — the console will run without the Terminal page"
        end
      end
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
