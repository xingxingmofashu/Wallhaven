import SwiftUI
import SwiftData

struct DetailView: View {
    @State private var viewModel: DetailViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationState.self) private var navigationState
    @State private var showShareSheet = false
    @State private var showInfoSheet = false

    init(wallpaper: Wallpaper) {
        _viewModel = State(initialValue: DetailViewModel(wallpaper: wallpaper))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            centeredImage
            Spacer()
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            topToolbar
            bottomToolbar
        }
        .task {
            viewModel.refreshFavoriteStatus(in: modelContext)
            viewModel.loadDetailIfNeeded()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: viewModel.shareItems)
        }
        .sheet(isPresented: $showInfoSheet) {
            infoSheet
        }
    }

    // MARK: - Top Toolbar

    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Open in Browser", systemImage: "safari") {
                    if let url = URL(string: viewModel.wallpaper.url) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Copy Link", systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = viewModel.wallpaper.url
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
    }

    // MARK: - Centered Image

    private var centeredImage: some View {
        CacheAsyncImage(url: viewModel.wallpaper.thumbnailURL) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
                .aspectRatio(viewModel.wallpaper.aspectRatio, contentMode: .fit)
        }
        .padding(.horizontal, 8)
    }
    // MARK: - Bottom Toolbar

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                showShareSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }

        ToolbarItemGroup(placement: .status) {
            Button {
                viewModel.toggleFavorite(in: modelContext)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(viewModel.isFavorited ? .pink : .primary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .symbolEffect(.bounce, value: viewModel.isFavorited)

            Button {
                showInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }

        ToolbarItem(placement: .bottomBar) {
            Button {
                viewModel.saveToPhotos()
            } label: {
                Image(systemName: "arrow.down.circle")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
    }
    // MARK: - Info Sheet

    private var infoSheet: some View {
        NavigationStack {
            List {
                Section("Details") {
                    ForEach(viewModel.formattedInfo, id: \.label) { item in
                        HStack {
                            Text(item.label)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.value)
                                .foregroundStyle(.primary)
                        }
                    }
                }

                if !viewModel.wallpaper.colors.isEmpty {
                    Section("Colors") {
                        HStack(spacing: 10) {
                            ForEach(viewModel.wallpaper.colors, id: \.self) { hex in
                                let cleanHex = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
                                Circle()
                                    .fill(Color(hex: cleanHex))
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().strokeBorder(Color(.systemGray4), lineWidth: 0.5))
                            }
                        }
                    }
                }

                if let tags = viewModel.wallpaper.tags, !tags.isEmpty {
                    Section("Tags") {
                        FlowLayoutView(spacing: 6) {
                            ForEach(tags) { tag in
                                Button {
                                    dismiss()
                                    navigationState.searchTag(tag.name)
                                } label: {
                                    Text("#\(tag.name)")
                                        .font(.caption)
                                        .foregroundStyle(.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if let uploader = viewModel.wallpaper.uploader {
                    Section("Uploader") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.secondary)
                            Text(uploader.username)
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(uploader.group)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showInfoSheet = false }
                }
            }
        }
    }
}
