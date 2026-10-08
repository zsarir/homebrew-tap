# phase-console-pro 6.2.1. Written by the publish script from its formula
# template on every release: edit the template, never this file.
class PhaseConsolePro < Formula
  desc "Local web console and autopilot for the phased-execution Claude Code skill"
  homepage "https://phase-console-site.vercel.app"
  url "https://registry.npmjs.org/phase-console-pro/-/phase-console-pro-6.2.1.tgz"
  # The shasum -a 256 of the tarball AS THE REGISTRY SERVES IT, read back after
  # the publish — never of a locally packed one.
  sha256 "e9672e646d2809e816392201180085a6e2433375cf65bf609ed139e07992f855"
  license :cannot_represent

  livecheck do
    url "https://registry.npmjs.org/phase-console-pro/latest"
    strategy :json do |json|
      json["version"]
    end
  end

  depends_on "node"

  def install
    # The tarball is the prebuilt package — the server bundled, the client built,
    # no install scripts — so this is a LOCAL install (prefix: false) in libexec
    # that only resolves the two optionalDependencies, node-pty and ws. The
    # package has top-level dotfiles (.build-rev, .claude-plugin/) that Dir["*"]
    # would leave behind; .brew_home is Homebrew's own.
    libexec.install Dir.glob("*", File::FNM_DOTMATCH) - %w[. .. .brew_home]
    cd libexec do
      system "npm", "install", *std_npm_args(prefix: false), "--omit=dev"
      # std_npm_args ignores install scripts. macOS is covered by node-pty's
      # shipped prebuilds, but no Linux prebuilds exist — compile it here with
      # the host toolchain Homebrew/Linux already requires. Tolerated on
      # failure: without the native module the console runs and the Terminal
      # page says why.
      if OS.linux?
        begin
          system "npm", "rebuild", "node-pty"
        rescue BuildError
          opoo "node-pty did not compile — the console will run without the Terminal page"
        end
      end
    end
    # An exec script rather than a symlink: it pins Homebrew's node, and hands
    # the CLI the upgrade-stable opt_libexec path — so anything the console
    # writes down (launchd plists) survives `brew upgrade`'s Cellar rename.
    (bin/"phase-console").write <<~SH
      #!/bin/bash
      exec "#{formula_opt_bin("node")}/node" "#{opt_libexec}/bin/phase-console.mjs" "$@"
    SH
  end

  def caveats
    <<~EOS
      Pro unlocks with your license key; until then the free features run:
        phase-console license activate PCP-XXXX-XXXX-XXXX-XXXX

      Point it at a repository that contains docs/plans:
        phase-console --root ~/code/your-repo

      Register the skill with Claude Code:
        phase-console install-plugin

      The autopilot, agent sessions and the plan wizard need the `claude` CLI
      on PATH. If the Terminal page reports node-pty missing, its native build
      was skipped — everything else works without it.

      Running the background agent? After `brew upgrade phase-console-pro`, run:
        phase-console --agent-restart
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/phase-console --version")
  end
end
