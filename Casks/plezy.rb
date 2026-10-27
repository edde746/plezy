cask "plezy" do
  version "2.24.0"
  sha256 "93ecd9ef7e59b297e64c887b8236472f006d1f1ddd2ba06dc93d952826150ff2"

  url "https://github.com/snapetech-org/PlezyNG/releases/download/#{version}/plezy-macos.dmg"
  name "Plezy"
  desc "Plex client with Jellyfin and Emby support, offline downloads, and HDR"
  homepage "https://github.com/snapetech-org/PlezyNG"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  app "Plezy.app"

  uninstall quit: "org.snapetech.plezyng"

  zap trash: [
    "~/Library/Application Support/org.snapetech.plezyng",
    "~/Library/Caches/org.snapetech.plezyng",
    "~/Library/HTTPStorages/org.snapetech.plezyng",
    "~/Library/Preferences/org.snapetech.plezyng.plist",
    "~/Library/Saved Application State/org.snapetech.plezyng.savedState",
    "~/Library/WebKit/org.snapetech.plezyng",
  ]
end
