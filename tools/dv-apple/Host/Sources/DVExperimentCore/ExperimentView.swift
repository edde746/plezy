import SwiftUI
import AetherEngine
import UniformTypeIdentifiers

/// Isolated research host. It neither changes PlezyNG's production Apple
/// engine nor promotes a selected route into a FEL/output qualification.
@MainActor
public struct DVExperimentRoot: View {
    @State private var engine: AetherEngine?
    @State private var startupError: String?

    public init() {}

    public var body: some View {
        Group {
            if let engine { ExperimentView(engine: engine) }
            else { Text(startupError ?? "Preparing experiment…") }
        }
        .task {
            guard engine == nil else { return }
            do { engine = try AetherEngine() }
            catch { startupError = "Engine initialization failed: \(error.localizedDescription)" }
        }
    }
}

@MainActor
private struct ExperimentView: View {
    @ObservedObject var engine: AetherEngine
    @State private var location = ""
    @State private var reconstruct = false
    @State private var loadTask: Task<Void, Never>?
    @State private var generation = 0
    @State private var errorText: String?
    @State private var requestedRoute = "No source loaded"
    @State private var fileImporterPresented = false
    @State private var selectedFileURL: URL?
    @State private var activeScopedFileURL: URL?

    var body: some View {
        VStack(spacing: 12) {
            AetherPlayerSurface(engine: engine)
                .frame(minHeight: 180)
            HStack {
                TextField("HTTPS media URL or choose a local video", text: $location)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Choose file") { fileImporterPresented = true }
            }
            Toggle("Reconstruct FEL (experimental)", isOn: $reconstruct)
            Text("Experimental metadata attachments are undocumented. A selected route or DV badge does not verify FEL pixels.")
                .font(.caption)
            HStack {
                Button("Load") { load() }
                Button("Play / Pause") { engine.togglePlayPause() }
                Button("Seek to 30s") { Task { await engine.seek(to: 30) } }
                Button("Stop") { stop() }
            }
            Text(requestedRoute)
            Text("Active route: \(String(describing: engine.videoRoute)); decoder: \(engine.activeVideoDecoder ?? "unknown")")
                .font(.caption)
            Text("EL reconstruction: unverified · Physical DV output: unverified")
                .font(.caption)
            if let errorText { Text(errorText).foregroundStyle(.red) }
        }
        .padding()
        .fileImporter(isPresented: $fileImporterPresented,
                      allowedContentTypes: [.movie, .video],
                      allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                selectedFileURL = url
                location = url.absoluteString
                errorText = nil
            } catch {
                errorText = "Could not open the selected file: \(error.localizedDescription)"
            }
        }
        .onDisappear { stop() }
    }

    private func load() {
        let importedURL = selectedFileURL?.absoluteString == location ? selectedFileURL : nil
        guard let url = importedURL ?? URL(string: location),
              url.scheme == "https" || url.isFileURL,
              url.user == nil, url.password == nil else {
            errorText = "Choose a local video or use an HTTPS media URL without embedded credentials."
            return
        }
        guard !reconstruct || AetherEngine.OptionalComponent.dualLayerDolbyVision.isBuiltIn else {
            errorText = "This build is missing the dual-layer component."
            return
        }
        stop()
        generation += 1
        let epoch = generation
        let selected = reconstruct
        if url.isFileURL && url.startAccessingSecurityScopedResource() {
            activeScopedFileURL = url
        }
        errorText = nil
        requestedRoute = selected ? "Requested: dual-layer FEL experiment" : "Requested: native compatibility"
        loadTask = Task {
            do {
                var options = LoadOptions()
                options.preferDualLayerDolbyVision = selected
                try await engine.load(url: url, options: options)
            } catch is CancellationError {
                // A newer load or Stop owns the surface now.
            } catch {
                if generation == epoch {
                    errorText = "Playback failed: \(error.localizedDescription)"
                    releaseScopedFile()
                }
            }
        }
    }

    private func stop() {
        generation += 1
        loadTask?.cancel()
        loadTask = nil
        engine.stop()
        releaseScopedFile()
    }

    private func releaseScopedFile() {
        activeScopedFileURL?.stopAccessingSecurityScopedResource()
        activeScopedFileURL = nil
    }
}
