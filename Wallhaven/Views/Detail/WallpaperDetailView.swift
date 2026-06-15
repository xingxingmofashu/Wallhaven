import SwiftUI
import SwiftData

struct WallpaperDetailView: View {
    @State private var viewModel: WallpaperDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showFullscreen = false
    @State private var showShareSheet = false
    @State private var showSaveToast   = false
    @State private var showFavToast    = false

    init(wallpaper: Wallpaper) {
        _viewModel = State(initialValue: WallpaperDetailViewModel(wallpaper: wallpaper))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroImage
                infoPanel
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .task {
            viewModel.checkFavoriteStatus(in: modelContext)
            viewModel.loadDetailIfNeeded()
        }
        .sheet(isPresented: $showFullscreen) {
            FullscreenImageView(url: viewModel.wallpaper.fullURL)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: viewModel.shareItems)
        }
        .overlay(alignment: .bottom) {
            if showSaveToast {
                saveToastView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if showFavToast, let toast = viewModel.favoriteToast {
                favToastView(toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: viewModel.saveResult) { _, result in
            guard result != nil else { return }
            showSaveToast = true
            Task {
                try? await Task.sleep(for: .seconds(2))
                showSaveToast = false
            }
        }
        .onChange(of: viewModel.favoriteToast) { _, toast in
            guard toast != nil else { return }
            showFavToast = true
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                showFavToast = false
            }
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        CacheAsyncImage(url: viewModel.wallpaper.thumbnailURL) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
                .aspectRatio(viewModel.wallpaper.aspectRatio, contentMode: .fit)
        }
        .onTapGesture { showFullscreen = true }
        .overlay(alignment: .bottomTrailing) {
            Button {
                showFullscreen = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding(12)
        }
    }

    // MARK: - Info Panel

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            actionButtons
            Divider()
            infoGrid

            if !viewModel.wallpaper.colors.isEmpty {
                colorRow
            }

            if let tags = viewModel.wallpaper.tags, !tags.isEmpty {
                tagSection(tags: tags)
            }

            if let uploader = viewModel.wallpaper.uploader {
                uploaderRow(uploader: uploader)
            }
        }
        .padding(16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.toggleFavorite(in: modelContext)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Label(
                    viewModel.isFavorited ? "Favorited" : "Favorite",
                    systemImage: viewModel.isFavorited ? "heart.fill" : "heart"
                )
                .frame(maxWidth: .infinity)
                .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.bordered)
            .tint(viewModel.isFavorited ? .pink : .primary)
            .symbolEffect(.bounce, value: viewModel.isFavorited)

            Button {
                viewModel.saveToPhotos()
            } label: {
                if viewModel.isSaving {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isSaving)

            Button {
                showShareSheet = true
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Info Grid

    private var infoGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            alignment: .leading,
            spacing: 10
        ) {
            ForEach(viewModel.formattedInfo, id: \.label) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.value)
                        .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    // MARK: - Color Row

    private var colorRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dominant Colors")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(viewModel.wallpaper.colors, id: \.self) { hex in
                    let cleanHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
                    Circle()
                        .fill(Color(hex: cleanHex))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                }
            }
        }
    }

    // MARK: - Tags

    private func tagSection(tags: [Tag]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tags")
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayoutView(spacing: 6) {
                ForEach(tags) { tag in
                    Text("#\(tag.name)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Uploader

    private func uploaderRow(uploader: Uploader) -> some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundStyle(.secondary)
            Text(uploader.username)
                .font(.subheadline)
            Text("·")
                .foregroundStyle(.secondary)
            Text(uploader.group)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isLoadingDetail {
                ProgressView()
            }
        }
    }

    // MARK: - Toast

    private var saveToastView: some View {
        let isSuccess: Bool
        let message: String

        switch viewModel.saveResult {
        case .success:
            isSuccess = true
            message = "Saved to photos"
        case .failure(let msg):
            isSuccess = false
            message = msg
        case nil:
            isSuccess = true
            message = ""
        }

        return Label(message, systemImage: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSuccess ? Color.green : Color.red)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .padding(.bottom, 30)
    }

    private func favToastView(_ toast: WallpaperDetailViewModel.FavoriteToast) -> some View {
        Label(toast.message, systemImage: toast == .added ? "heart.fill" : "heart.slash")
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.pink)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .padding(.bottom, 30)
    }
}

#Preview {
    NavigationStack {
        WallpaperDetailView(wallpaper: .preview)
    }
}
