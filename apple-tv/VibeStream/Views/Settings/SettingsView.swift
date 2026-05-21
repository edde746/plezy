import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = SettingsViewModel()
    @State private var showSignOutConfirm = false
    @State private var showProfileSwitch = false
    @State private var showIconPicker = false
    @State private var awardsRefreshed = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Header
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 80)
                    .padding(.top, 20)

                // Account section
                accountSection

                // Playback section
                playbackSection

                // Appearance section
                appearanceSection

                // App Icon section
                appIconSection

                // Storage section
                storageSection

                // About section
                aboutSection

                // Sign out
                signOutSection
            }
            .padding(.bottom, 80)
        }
        .background {
            LinearGradient(
                stops: [
                    .init(color: Color(white: 0.12), location: 0),
                    .init(color: Color(white: 0.05), location: 0.5),
                    .init(color: .black, location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                viewModel.signOut(appState: appState)
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showProfileSwitch) {
            ProfileSwitchView()
        }
        .sheet(isPresented: $showIconPicker) {
            AppIconPickerSheet(
                selectedIcon: viewModel.selectedAppIcon,
                onSelect: { variant in
                    showIconPicker = false
                    viewModel.changeAppIcon(to: variant)
                }
            )
        }
        .task {
            await viewModel.loadCacheSize()
        }
    }

    // MARK: - Account

    @ViewBuilder
    private var accountSection: some View {
        SettingsSection(title: "Account") {
            if let user = appState.activeUser {
                HStack(spacing: 20) {
                    if let thumb = user.thumb, let url = URL(string: thumb) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.displayName)
                            .font(.title3)
                            .fontWeight(.semibold)
                        if let email = user.email {
                            Text(email)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        if let server = appState.activeServer {
                            Text(server.name)
                                .font(.callout)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    Button("Switch Profile") {
                        showProfileSwitch = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Playback

    @ViewBuilder
    private var playbackSection: some View {
        SettingsSection(title: "Playback") {
            VStack(spacing: 16) {
                SettingsOptionRow(
                    title: "Video Player",
                    subtitle: "Choose the video playback engine.",
                    options: VideoPlayerType.allCases,
                    selection: Binding(
                        get: { viewModel.videoPlayerType },
                        set: { viewModel.videoPlayerType = $0 }
                    ),
                    label: { $0.displayTitle },
                    detail: { $0.detail }
                )

                SettingsToggleRow(
                    title: "Auto-Play Next Episode",
                    subtitle: "Automatically play the next episode when the current one ends.",
                    isOn: Binding(
                        get: { viewModel.autoPlayNext },
                        set: { viewModel.autoPlayNext = $0 }
                    )
                )

                SettingsToggleRow(
                    title: "Auto-Preview",
                    subtitle: "Play a trailer preview in the background when browsing content.",
                    isOn: Binding(
                        get: { viewModel.autoPreview },
                        set: { viewModel.autoPreview = $0 }
                    )
                )

                SettingsOptionRow(
                    title: "Preview Audio",
                    subtitle: "When to play audio during trailer previews.",
                    options: PreviewAudioMode.allCases,
                    selection: Binding(
                        get: { viewModel.previewAudioMode },
                        set: { viewModel.previewAudioMode = $0 }
                    ),
                    label: { $0.displayTitle },
                    detail: { $0.detail }
                )

                SettingsOptionRow(
                    title: "Video Quality",
                    subtitle: "Default quality for all playback. Can be changed per session in the player.",
                    options: PlexClient.VideoQuality.allCases,
                    selection: Binding(
                        get: { viewModel.defaultVideoQuality },
                        set: { viewModel.defaultVideoQuality = $0 }
                    ),
                    label: { $0.displayTitle },
                    detail: { $0.detail }
                )

            }
        }
    }

    // MARK: - Appearance

    @ViewBuilder
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            SettingsOptionRow(
                title: "Episode View",
                subtitle: "Choose how episodes are displayed throughout the app.",
                options: EpisodeViewMode.allCases,
                selection: Binding(
                    get: { viewModel.episodeViewMode },
                    set: { viewModel.episodeViewMode = $0 }
                ),
                label: { $0.displayTitle },
                detail: { $0.detail }
            )
        }
    }

    // MARK: - App Icon

    @FocusState private var isAppIconFocused: Bool

    @ViewBuilder
    private var appIconSection: some View {
        SettingsSection(title: "App Icon") {
            HStack(spacing: 20) {
                Image(viewModel.selectedAppIcon.previewImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedAppIcon.displayName)
                        .font(.callout)
                    Text("Tap to change the app icon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(isAppIconFocused ? 0.1 : 0))
            )
            .scaleEffect(isAppIconFocused ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isAppIconFocused)
            .focusable()
            .focused($isAppIconFocused)
            .onPlayPauseCommand { showIconPicker = true }
            .onTapGesture { showIconPicker = true }
        }
    }

    // MARK: - Storage

    @ViewBuilder
    private var storageSection: some View {
        SettingsSection(title: "Storage") {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image Cache")
                            .font(.callout)
                        Text(viewModel.cacheSizeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(viewModel.cacheCleared ? "Cleared" : "Clear Cache") {
                        Task { await viewModel.clearImageCache() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.cacheCleared)
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Award Badges")
                            .font(.callout)
                        Text("Refresh Oscar, Emmy, and other award data.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(awardsRefreshed ? "Refreshed" : "Refresh") {
                        Task {
                            await OmdbService.shared.clearCache()
                            awardsRefreshed = true
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(awardsRefreshed)
                }
            }
        }
    }

    // MARK: - About

    @ViewBuilder
    private var aboutSection: some View {
        SettingsSection(title: "About") {
            VStack(spacing: 12) {
                SettingsInfoRow(label: "App", value: "Vibe for Apple TV")
                SettingsInfoRow(label: "Version", value: viewModel.appVersion)
            }
        }
    }

    // MARK: - Sign Out

    @ViewBuilder
    private var signOutSection: some View {
        VStack {
            Button(role: .destructive) {
                showSignOutConfirm = true
            } label: {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal, 80)
        }
    }
}

// MARK: - Reusable Components

private struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 80)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 60)
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isOn ? .green : .secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(isFocused ? 0.1 : 0))
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand {
            withAnimation(.easeInOut(duration: 0.15)) { isOn.toggle() }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) { isOn.toggle() }
        }
    }
}

private struct SettingsOptionRow<Option: Hashable>: View {
    let title: String
    let subtitle: String
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    var detail: ((Option) -> String?)? = nil

    @State private var showPicker = false
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 6) {
                Text(label(selection))
                    .font(.callout)
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(isFocused ? 0.1 : 0))
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand { showPicker = true }
        .onTapGesture { showPicker = true }
        .sheet(isPresented: $showPicker) {
            SettingsPickerSheet(
                title: title,
                options: options,
                selection: $selection,
                label: label,
                detail: detail
            )
        }
    }
}

private struct SettingsPickerSheet<Option: Hashable>: View {
    let title: String
    let options: [Option]
    @Binding var selection: Option
    let label: (Option) -> String
    var detail: ((Option) -> String?)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    if index > 0 {
                        Divider().opacity(0.3)
                    }
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            selection = option
                        }
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label(option))
                                    .font(.body)
                                if let detail, let detailText = detail(option) {
                                    Text(detailText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if option == selection {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(40)
    }
}

private struct SettingsInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout)
        }
    }
}

// MARK: - App Icon Picker

private struct AppIconPickerSheet: View {
    let selectedIcon: AppIconVariant
    let onSelect: (AppIconVariant) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("App Icon")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(AppIconVariant.allCases.enumerated()), id: \.element.id) { index, variant in
                    if index > 0 {
                        Divider().opacity(0.3)
                    }
                    Button {
                        onSelect(variant)
                    } label: {
                        HStack(spacing: 16) {
                            Image(variant.previewImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text(variant.displayName)
                                .font(.body)

                            Spacer()

                            if variant == selectedIcon {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(40)
    }
}

// MARK: - Profile Switch

struct ProfileSwitchView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var homeUsers: [PlexHomeUser] = []
    @State private var isLoading = true
    @State private var selectedUser: PlexHomeUser?
    @State private var showPinEntry = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading profiles...")
                } else if showPinEntry, let user = selectedUser {
                    PINKeypad(
                        title: "Enter PIN",
                        subtitle: user.displayName,
                        onSubmit: { pin in
                            Task { await switchTo(user: user, pin: pin) }
                        },
                        onCancel: {
                            showPinEntry = false
                            selectedUser = nil
                        }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(homeUsers, id: \.uuid) { user in
                                ProfileRow(user: user) {
                                    if user.hasPassword == true || user.protected == true {
                                        selectedUser = user
                                        showPinEntry = true
                                    } else {
                                        Task { await switchTo(user: user, pin: nil) }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle(showPinEntry ? "" : "Switch Profile")
            .toolbar {
                if !showPinEntry {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .task {
                await loadUsers()
            }
        }
    }

    private func loadUsers() async {
        guard let token = appState.authToken else { return }
        let authService = PlexAuthService(clientIdentifier: appState.clientIdentifier)
        do {
            homeUsers = try await authService.getHomeUsers(token: token)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func switchTo(user: PlexHomeUser, pin: String?) async {
        guard let token = appState.authToken else { return }
        let authService = PlexAuthService(clientIdentifier: appState.clientIdentifier)
        do {
            let newToken = try await authService.switchToUser(uuid: user.uuid, pin: pin, token: token)
            let userInfo = try await authService.getUserInfo(token: newToken)
            appState.authToken = newToken
            appState.updateUser(userInfo)
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        selectedUser = nil
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let user: PlexHomeUser
    var onSelect: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let thumb = user.thumb, let url = URL(string: thumb) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .accessibilityHidden(true)
            } else {
                Image(systemName: "person.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 50, height: 50)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .font(.headline)
                if user.admin == true {
                    Text("Admin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if user.hasPassword == true || user.protected == true {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isFocused ? .white : .white.opacity(0.08))
        )
        .foregroundStyle(isFocused ? .black : .white)
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onPlayPauseCommand { onSelect() }
        .onTapGesture { onSelect() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [user.displayName]
        if user.admin == true { parts.append("Admin") }
        if user.hasPassword == true || user.protected == true { parts.append("PIN protected") }
        return parts.joined(separator: ", ")
    }
}
