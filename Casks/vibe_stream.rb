cask "vibe_stream" do
  version "2.1.0"
  sha256 "9219831cab16f33b3b7a1223f3a120aa8aed44a28352839f3ec5fb569be77cd6"

  url "https://github.com/MazeDev7/alflix/releases/download/#{version}/vibe_stream-macos.dmg"
  name "Vibe"
  desc "Modern Plex and Jellyfin client built with Flutter"
  homepage "https://github.com/MazeDev7/alflix"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  app "Vibe.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Vibe.app"],
                   sudo: false
  end

  uninstall quit: "com.amaze.vibestream"

  zap trash: [
    "~/Library/Application Support/com.amaze.vibestream",
    "~/Library/Caches/com.amaze.vibestream",
    "~/Library/HTTPStorages/com.amaze.vibestream",
    "~/Library/Preferences/com.amaze.vibestream.plist",
    "~/Library/Saved Application State/com.amaze.vibestream.savedState",
    "~/Library/WebKit/com.amaze.vibestream",
  ]
end
