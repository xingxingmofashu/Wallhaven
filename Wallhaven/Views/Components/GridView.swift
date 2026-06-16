import SwiftUI

/// Reusable wallpaper grid, two-column waterfall layout
struct GridView: View {
    let wallpapers: [Wallpaper]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onSelect: (Wallpaper) -> Void
    let onSelectIndex: (Int) -> Void
    let contextMenu: ((Wallpaper) -> AnyView)?

    init(
        wallpapers: [Wallpaper],
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        onSelect: @escaping (Wallpaper) -> Void = { _ in },
        onSelectIndex: @escaping (Int) -> Void = { _ in },
        contextMenu: ((Wallpaper) -> AnyView)? = nil
    ) {
        self.wallpapers = wallpapers
        self.isLoadingMore = isLoadingMore
        self.onLoadMore = onLoadMore
        self.onSelect = onSelect
        self.onSelectIndex = onSelectIndex
        self.contextMenu = contextMenu
    }

    private let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let columnWidth = (geo.size.width - spacing * 3) / 2

            ScrollView {
                if columnWidth > 0 {
                    HStack(alignment: .top, spacing: spacing) {
                        columnWallpapers(leftWallpapers, columnWidth: columnWidth)
                        columnWallpapers(rightWallpapers, columnWidth: columnWidth)
                    }
                    .padding(.horizontal, spacing)
                    .padding(.top, spacing)
                }

                if isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    // MARK: - Columns

    private var leftWallpapers: [Wallpaper] {
        stride(from: 0, to: wallpapers.count, by: 2).map { wallpapers[$0] }
    }

    private var rightWallpapers: [Wallpaper] {
        stride(from: 1, to: wallpapers.count, by: 2).map { wallpapers[$0] }
    }

    @ViewBuilder
    private func columnWallpapers(_ items: [Wallpaper], columnWidth: CGFloat) -> some View {
        LazyVStack(spacing: spacing) {
            ForEach(items) { wallpaper in
                let cellHeight = cellHeight(for: wallpaper, width: columnWidth)

                Button {
                    onSelect(wallpaper)
                    if let idx = wallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
                        onSelectIndex(idx)
                    }
                } label: {
                    CellView(wallpaper: wallpaper)
                        .frame(width: columnWidth, height: cellHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .contextMenu {
                    if let contextMenu = contextMenu {
                        contextMenu(wallpaper)
                    }
                }
                .onAppear {
                    if wallpaper.id == wallpapers.last?.id, !isLoadingMore {
                        onLoadMore()
                    }
                }
            }
        }
    }

    private func cellHeight(for wallpaper: Wallpaper, width: CGFloat) -> CGFloat {
        guard width > 0 else { return 200 }
        let ratio = max(wallpaper.aspectRatio, 0.01)
        return width / ratio
    }
}

#Preview {
    GridView(
        wallpapers: [.preview, .preview, .preview, .preview],
        isLoadingMore: false,
        onLoadMore: {},
        onSelect: { _ in }
    )
}
