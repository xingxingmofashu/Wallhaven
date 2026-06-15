import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showAPIKeyField = false
    @State private var tempAPIKey      = ""
    @State private var showClearCacheAlert = false
    @State private var showClearedToast   = false

    var body: some View {
        NavigationStack {
            Form {
                apiKeySection
                if viewModel.hasAPIKey { remoteSettingsSection }
                cacheSection
                aboutSection
            }
            .navigationTitle("设置")
            .task {
                tempAPIKey = viewModel.apiKey
                if viewModel.hasAPIKey { viewModel.fetchUserSettings() }
            }
            .overlay(alignment: .bottom) {
                if showClearedToast {
                    Label("缓存已清除", systemImage: "checkmark.circle.fill")
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - API Key Section

    private var apiKeySection: some View {
        Section {
            if showAPIKeyField {
                HStack {
                    SecureField("粘贴 API Key", text: $tempAPIKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("保存") {
                        viewModel.apiKey = tempAPIKey.trimmingCharacters(in: .whitespaces)
                        showAPIKeyField  = false
                        if viewModel.hasAPIKey { viewModel.fetchUserSettings() }
                    }
                    .fontWeight(.semibold)
                }
            } else {
                HStack {
                    Label(
                        viewModel.hasAPIKey ? "已设置 API Key" : "未设置 API Key",
                        systemImage: viewModel.hasAPIKey ? "key.fill" : "key"
                    )
                    .foregroundStyle(viewModel.hasAPIKey ? .green : .secondary)
                    Spacer()
                    Button(viewModel.hasAPIKey ? "更改" : "设置") {
                        tempAPIKey = viewModel.apiKey
                        showAPIKeyField = true
                    }
                    .font(.subheadline)
                }

                if viewModel.hasAPIKey {
                    Button("清除 API Key", role: .destructive) {
                        viewModel.apiKey = ""
                        tempAPIKey = ""
                    }
                }
            }
        } header: {
            Text("Wallhaven API Key")
        } footer: {
            Text("API Key 可在 wallhaven.cc 账号设置中获取。设置后可访问 NSFW 内容及个人设置。")
        }
    }

    // MARK: - Remote Settings Section

    private var remoteSettingsSection: some View {
        Section("账号偏好（来自 Wallhaven）") {
            if viewModel.isLoadingSettings {
                HStack {
                    ProgressView()
                    Text("同步中…").foregroundStyle(.secondary)
                }
            } else if let s = viewModel.userSettings {
                settingsRow("默认纯度",  value: s.purity.joined(separator: ", "))
                settingsRow("默认分类",  value: s.categories.joined(separator: ", "))
                settingsRow("首选分辨率", value: s.resolutions.isEmpty ? "不限" : s.resolutions.joined(separator: ", "))
                settingsRow("首选比例",  value: s.aspectRatios.isEmpty ? "不限" : s.aspectRatios.joined(separator: ", "))
                settingsRow("排行榜范围", value: s.toplistRange)
            } else if let err = viewModel.settingsError {
                Label(err, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline)
        }
    }

    // MARK: - Cache Section

    private var cacheSection: some View {
        Section("缓存") {
            Button("清除图片缓存") {
                showClearCacheAlert = true
            }
            .alert("清除缓存", isPresented: $showClearCacheAlert) {
                Button("清除", role: .destructive) {
                    viewModel.clearImageCache()
                    withAnimation {
                        showClearedToast = true
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { showClearedToast = false }
                    }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("将清除内存中的图片缓存。")
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("关于") {
            HStack {
                Text("版本")
                Spacer()
                Text("\(viewModel.appVersion) (\(viewModel.buildNumber))")
                    .foregroundStyle(.secondary)
            }
            Link("Wallhaven 网站", destination: URL(string: "https://wallhaven.cc")!)
            Link("API 文档", destination: URL(string: "https://wallhaven.cc/help/api")!)
        }
    }
}

#Preview {
    SettingsView()
}
