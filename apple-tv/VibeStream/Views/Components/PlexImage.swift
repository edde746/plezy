import SwiftUI

struct PlexImage: View {
    let path: String?
    let token: String
    let baseURL: String
    var width: CGFloat = 200
    var aspectRatio: CGFloat = 2/3
    var tmdbId: String?
    var mediaType: String = "movie"

    @State private var image: UIImage?
    @State private var isLoading = true

    private var fullURL: URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        // Use Plex photo transcoder to request appropriately sized images
        // Request 2x for Retina display
        let scaledWidth = Int(width * 2)
        let scaledHeight = Int(width / aspectRatio * 2)
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return URL(string: "\(baseURL)\(path)?X-Plex-Token=\(token)")
        }
        return URL(string: "\(baseURL)/photo/:/transcode?width=\(scaledWidth)&height=\(scaledHeight)&minSize=1&upscale=1&url=\(encodedPath)&X-Plex-Token=\(token)")
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        ProgressView()
                    }
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .frame(width: width, height: width / aspectRatio)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
        .task(id: path) {
            await loadImage()
        }
    }

    /// Whether this image is a large backdrop that benefits from TMDB's
    /// higher-resolution source over the Plex transcoder.
    private var preferTmdbBackdrop: Bool {
        aspectRatio > 1 && width >= 300 && tmdbId != nil && !(tmdbId ?? "").isEmpty
    }

    private func loadImage() async {
        isLoading = true

        // For large landscape backdrops, prefer TMDB's original-resolution
        // images over Plex's transcoder which may only have a low-res source.
        if preferTmdbBackdrop, let tmdbId {
            let tmdbType = (mediaType == "show" || mediaType == "episode" || mediaType == "season") ? "show" : "movie"
            if let tmdbURL = await TmdbService.shared.getBackdropURL(tmdbId: tmdbId, mediaType: tmdbType),
               let url = URL(string: tmdbURL),
               let loaded = await ImageLoader.shared.loadImage(from: url) {
                image = loaded
                isLoading = false
                return
            }
        }

        // Try Plex image
        if let url = fullURL {
            if let loaded = await ImageLoader.shared.loadImage(from: url, token: token) {
                image = loaded
                isLoading = false
                return
            }
        }

        // Fallback to TMDB for non-backdrop cases (posters, small cards)
        if !preferTmdbBackdrop, let tmdbId, !tmdbId.isEmpty {
            let tmdbType = (mediaType == "show" || mediaType == "episode" || mediaType == "season") ? "show" : "movie"
            let tmdbURL: String? = if aspectRatio > 1 {
                await TmdbService.shared.getBackdropURL(tmdbId: tmdbId, mediaType: tmdbType)
            } else {
                await TmdbService.shared.getPosterURL(tmdbId: tmdbId, mediaType: tmdbType)
            }
            if let tmdbURL, let url = URL(string: tmdbURL) {
                image = await ImageLoader.shared.loadImage(from: url)
                isLoading = false
                return
            }
        }

        isLoading = false
    }
}
