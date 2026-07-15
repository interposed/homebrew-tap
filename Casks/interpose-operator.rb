cask "interpose-operator" do
  version "1.6.1"
  sha256 "e9282f1a82f89bc0e2ef24ee98045afa5479da604ddc55f20ced80c95b28952e"

  url "https://github.com/interposed/interpose-operator-releases/releases/download/v#{version}/InterposeOperator.app.zip"
  name "Interpose Operator"
  desc "Cross-platform operator console for interposed"
  homepage "https://interposed.ai"

  # The FIDO bridge helper is dynamically linked against libfido2 at runtime.
  depends_on formula: "libfido2"

  app "InterposeOperator.app"

  # The app is UNSIGNED (the Apple Developer account was terminated). Strip the
  # quarantine attribute so `brew install --cask` opens it with NO Gatekeeper
  # wall — legitimate for a self-distributed third-party tap. Then install the
  # bundled FIDO bridge + a LaunchAgent so hardware-key approvals work and the
  # bridge auto-starts on login.
  postflight do
    require "fileutils"

    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/InterposeOperator.app"]

    support    = File.expand_path("~/Library/Application Support/interpose-operator")
    bridge_src = "#{appdir}/InterposeOperator.app/Contents/Resources/interpose-fido-bridge"
    bridge_dst = "#{support}/interpose-fido-bridge"
    next unless File.exist?(bridge_src)

    FileUtils.mkdir_p(support)
    FileUtils.cp(bridge_src, bridge_dst)
    FileUtils.chmod(0o755, bridge_dst)

    agents = File.expand_path("~/Library/LaunchAgents")
    FileUtils.mkdir_p(agents)
    plist = "#{agents}/ai.interposed.fido-bridge.plist"
    File.write(plist, <<~PLIST)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key><string>ai.interposed.fido-bridge</string>
        <key>ProgramArguments</key>
        <array><string>#{bridge_dst}</string></array>
        <key>RunAtLoad</key><true/>
        <key>KeepAlive</key><true/>
        <key>StandardOutPath</key><string>/tmp/interpose-fido-bridge.log</string>
        <key>StandardErrorPath</key><string>/tmp/interpose-fido-bridge.log</string>
      </dict>
      </plist>
    PLIST
    # Modern launchctl (bootout/bootstrap) — load/unload is deprecated and prints
    # a spurious "Input/output error" on Sequoia. bootout clears any stale copy;
    # bootstrap loads the agent for this GUI session (RunAtLoad also starts it).
    uid = Process.uid
    system_command "/bin/launchctl", args: ["bootout", "gui/#{uid}/ai.interposed.fido-bridge"], must_succeed: false
    system_command "/bin/launchctl", args: ["bootstrap", "gui/#{uid}", plist], must_succeed: false
  end

  uninstall_postflight do
    require "fileutils"
    plist = File.expand_path("~/Library/LaunchAgents/ai.interposed.fido-bridge.plist")
    system_command "/bin/launchctl", args: ["bootout", "gui/#{Process.uid}/ai.interposed.fido-bridge"], must_succeed: false
    FileUtils.rm_f(plist)
    FileUtils.rm_f(File.expand_path("~/Library/Application Support/interpose-operator/interpose-fido-bridge"))
  end

  # `brew uninstall --zap` also removes operator identity, pairing, license, and
  # seal-cred. A plain uninstall leaves those so a reinstall keeps the fleet.
  zap trash: [
    "~/Library/Application Support/interpose-operator",
    "~/Library/LaunchAgents/ai.interposed.fido-bridge.plist",
    "~/.config/interpose",
  ]
end
