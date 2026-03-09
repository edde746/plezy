cask "plezy" do
  version "1.25.1"
  sha256 "213d75905ab81ce6ae9142771bd3ce130499612c52ede15b5af65f609f43bd65"

  url "https://github.com/edde746/plezy/releases/download/#{version}/plezy-macos.dmg"
  name "Plezy"
  desc "Modern Plex client built with Flutter"
  homepage "https://github.com/edde746/plezy"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  app "Plezy.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Plezy.app"],
                   sudo: false
  end

  uninstall quit: "com.edde746.plezy"

  zap trash: [
    "~/Library/Application Support/com.edde746.plezy",
    "~/Library/Caches/com.edde746.plezy",
    "~/Library/HTTPStorages/com.edde746.plezy",
    "~/Library/Preferences/com.edde746.plezy.plist",
    "~/Library/Saved Application State/com.edde746.plezy.savedState",
    "~/Library/WebKit/com.edde746.plezy",
  ]
end
