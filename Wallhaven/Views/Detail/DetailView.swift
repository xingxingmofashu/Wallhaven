import SwiftUI
import SwiftData

struct DetailView: View {
    @State private var viewModel: DetailViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationState.self) private var navigationState
    @State private var showShareSheet = false
    @State private var showInfoSheet = false
    @State private var scrollPosition: Int?
    @State private var wallpapers: [Wallpaper]
    @State private var selectedIndex: Int

    private var currentID: String? { wallpapers.indices.contains(selectedIndex) ? wallpapers[selectedIndex].id : nil }

    init(wallpaper: Wallpaper, relatedWallpapers: [Wallpaper] = []) {
        _viewModel = State(initialValue: DetailViewModel(wallpaper: wallpaper, relatedWallpapers: relatedWallpapers))
        _wallpapers = State(initialValue: [wallpaper])
        _selectedIndex = State(initialValue: 0)
        _scrollPosition = State(initialValue: 0)
    }

    init(wallpapers: [Wallpaper], startIndex: Int) {
        let wallpaper = wallpapers[startIndex]
        _viewModel = State(initialValue: DetailViewModel(wallpaper: wallpaper, relatedWallpapers: wallpapers))
        _wallpapers = State(initialValue: wallpapers)
        _selectedIndex = State(initialValue: startIndex)
        _scrollPosition = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(Array(wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                            imageView(for: wallpaper)
                                .containerRelativeFrame(.horizontal)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrollPosition)

                relatedThumbnailList
                    .frame(height: 44)
                    .opacity(viewModel.relatedWallpapers.isEmpty ? 0 : 1)
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let vertical = value.translation.height
                    let horizontal = value.translation.width
                    if vertical > 80 && abs(horizontal) < abs(vertical) {
                        dismiss()
                    }
                }
        )
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            topToolbar
            bottomToolbar
        }
        .onChange(of: scrollPosition) { _, newValue in
            guard let index = newValue, wallpapers.indices.contains(index), index != selectedIndex else { return }
            selectedIndex = index
            viewModel.selectRelated(wallpapers[index])
            preloadAdjacent(at: index)
        }
        .task {
            viewModel.refreshFavoriteStatus(in: modelContext)
            viewModel.loadDetailIfNeeded()
            viewModel.loadRelatedWallpapers()
            preloadAdjacent(at: selectedIndex)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheetView(items: viewModel.shareItems)
        }
        .sheet(isPresented: $showInfoSheet) {
            infoSheet
        }
    }

    // MARK: - Image View

    private func preloadAdjacent(at index: Int) {
        for offset in [-1, 1] {
            let target = index + offset
            if wallpapers.indices.contains(target), let url = wallpapers[target].fullURL {
                CacheImage.shared.preload(url: url)
            }
        }
    }

    private func imageView(for wallpaper: Wallpaper) -> some View {
        CacheAsyncImage(url: wallpaper.fullURL) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            CacheAsyncImage(url: wallpaper.thumbnailURL) { thumb in
                thumb
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(wallpaper.aspectRatio, contentMode: .fit)
            }
        }
    }

    // MARK: - Related Thumbnail List

    private var relatedThumbnailList: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.relatedWallpapers) { wallpaper in
                        Button {
                            if let idx = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
                                scrollPosition = idx
                            } else {
                                wallpapers = [wallpaper]
                                scrollPosition = 0
                                viewModel.selectRelated(wallpaper)
                            }
                        } label: {
                            CacheAsyncImage(url: wallpaper.thumbnailURL) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                            }
                            .frame(width: 60, height: 42)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(wallpaper.id == currentID ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            .overlay(alignment: .topTrailing) {
                                if viewModel.favoritedIDs.contains(wallpaper.id) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(.pink)
                                        .padding(3)
                                }
                            }
                            .id(wallpaper.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
            }
            .onChange(of: selectedIndex) { _, _ in
                withAnimation {
                    proxy.scrollTo(currentID, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(currentID, anchor: .center)
            }
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
                        FlowLayout(spacing: 6) {
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
