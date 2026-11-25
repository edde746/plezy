import SwiftUI
import PlezyKit

/// Open source licenses: every component the app ships, by name with its licence, each opening its detail (`name`:
/// that component's) with its source link and its licence texts, reflowed to the width. Harness names:
/// `settings.licenses.<i>`, `settings.license.<url|text.i.j>`.
struct LicensesScreen: View {
    let app: AppModel
    let name: String?

    @State private var model: SettingsStoreModel<LicensesStore, LicensesUiState>?

    init(app: AppModel, route: any Route, name: String?) {
        self.app = app
        self.name = name
        _model = State(initialValue: .retained(
            app: app, route: route, key: "settings.licenses",
            create: { app.session.settings.licenses(name: name) },
            flow: { $0.state },
            release: { $0.release() }
        ))
    }

    var body: some View {
        if let model {
            if name != nil, let detail = model.state.state.detail {
                LicenseDetail(app: app, detail: detail)
                    .task { await model.state.observe() }
            } else {
                LicenseList(app: app, entries: model.state.state.entries)
            }
        }
    }
}

private struct LicenseList: View {
    let app: AppModel
    let entries: [LicenseEntryUi]

    var body: some View {
        SettingsPageFrame(title: T.shared.about.openSourceLicenses, id: SettingsPageId.licenses.probe) {
            Form {
                Section {
                    ForEach(Array(entries.enumerated()), id: \.element.name) { index, entry in
                        SettingsLinkRow(title: entry.name, subtitle: entry.license, id: "settings.licenses.\(index)") {
                            app.navigator.navigate(route: RouteSettingsPage(page: .licenses, arg: entry.name))
                        }
                    }
                }
            }
            .settingsForm()
        }
    }
}

/// One component: its licence and source link, then each licence text under its title, paragraph by paragraph (each
/// focusable on Apple TV, so a remote scrolls through a long text).
private struct LicenseDetail: View {
    let app: AppModel
    let detail: LicenseDetailUi

    var body: some View {
        SettingsPageFrame(title: detail.name, id: "settings.page.license") {
            Form {
                Section {
                    SettingsLinkRow(
                        title: detail.license, subtitle: detail.url, systemImage: SettingIcon.openInNew.systemImage,
                        trailingSymbol: "arrow.up.right", id: "settings.license.url"
                    ) {
                        app.session.openUrl(url: detail.url)
                    }
                }
                if let texts = detail.texts {
                    ForEach(Array(texts.enumerated()), id: \.offset) { index, text in
                        Section(text.title) {
                            ForEach(Array(text.paragraphs.enumerated()), id: \.offset) { line, paragraph in
                                Text(paragraph)
                                    .font(.footnote)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    #if os(tvOS)
                                    .focusable()
                                    #endif
                                    .accessibilityIdentifier("settings.license.text.\(index).\(line)")
                            }
                        }
                    }
                } else {
                    Section {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .settingsForm()
        }
    }
}
