import SwiftUI
import SwiftData

struct WallpaperDetailView: View {
    @State private var viewModel: WallpaperDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var favVM       = FavoritesViewModel()
    @State private var showFullscreen = false
    @State private var showShareSheet = false
    @State private var showSaveToast  = false

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
        .task { viewModel.loadDetailIfNeeded() }
        .sheet(isPresented: $showFullscreen) {
            FullscreenImageView(url: viewModel.wallpaper.fullURL)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: viewModel.shareItems)
        }
        .overlay(alignment: .bottom) {
            if showSaveToast {
                toastView
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
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        CachedAsyncImage(url: viewModel.wallpaper.thumbnailURL) { image in
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
            // Action buttons row
            actionButtons

            Divider()

            // Basic info
            infoGrid

            // Colors
            if !viewModel.wallpaper.colors.isEmpty {
                colorRow
            }

            // Tags
            if let tags = viewModel.wallpaper.tags, !tags.isEmpty {
                tagSection(tags: tags)
            }

            // Uploader
            if let uploader = viewModel.wallpaper.uploader {
                uploaderRow(uploader: uploader)
            }
        }
        .padding(16)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Favorite
            let isFav = favVM.isFavorite(id: viewModel.wallpaper.id, context: modelContext)
            Button {
                favVM.toggle(wallpaper: viewModel.wallpaper, context: modelContext)
            } label: {
                Label(
                    isFav ? "Favorited" : "Favorite",
                    systemImage: isFav ? "heart.fill" : "heart"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(isFav ? .pink : .primary)

            // Save to photos
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

            // Share
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
            FlowLayout(spacing: 6) {
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

    private var toastView: some View {
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
}

// MARK: - Fullscreen Image View

struct FullscreenImageView: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { scale = max(1, $0) }
                            .onEnded { _ in
                                withAnimation { if scale < 1 { scale = 1 } }
                            }
                        .simultaneously(
                            with: DragGesture()
                                .onChanged { offset = $0.translation }
                                .onEnded { _ in
                                    if scale <= 1 {
                                        withAnimation { offset = .zero }
                                    }
                                }
                        )
                    )
            } placeholder: {
                ProgressView().tint(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - FlowLayout (tag flow layout)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var x: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                height += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    NavigationStack {
        WallpaperDetailView(wallpaper: .preview)
    }
}
