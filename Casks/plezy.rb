cask "plezy" do
  version "1.16.0"
  sha256 "65f4d629dd98e90dace71166a279a5b58334182ca7f60f85a79b3a4e2e2f8a02"

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
