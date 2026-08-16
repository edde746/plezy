cask "plezy" do
  version "2.14.0"
  sha256 "35fcbc5bcad13691fda335f662af0e9e5ffd0d9d202ecae17705a25cda2f58a6"

  url "https://github.com/edde746/plezy/releases/download/#{version}/plezy-macos.dmg"
  name "Plezy"
  desc "Modern Plex and Jellyfin client built with Flutter"
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
