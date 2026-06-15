import SwiftUI

/// Reusable wallpaper grid, two-column waterfall layout
struct GridView: View {
    let wallpapers: [Wallpaper]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onSelect: (Wallpaper) -> Void
    let contextMenu: ((Wallpaper) -> AnyView)?

    init(
        wallpapers: [Wallpaper],
        isLoadingMore: Bool = false,
        onLoadMore: @escaping () -> Void = {},
        onSelect: @escaping (Wallpaper) -> Void = { _ in },
        contextMenu: ((Wallpaper) -> AnyView)? = nil
    ) {
        self.wallpapers = wallpapers
        self.isLoadingMore = isLoadingMore
        self.onLoadMore = onLoadMore
        self.onSelect = onSelect
        self.contextMenu = contextMenu
    }

    private let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let columnWidth = (geo.size.width - spacing * 3) / 2

            ScrollView {
                HStack(alignment: .top, spacing: spacing) {
                    columnWallpapers(leftIndices, columnWidth: columnWidth)
                    columnWallpapers(rightIndices, columnWidth: columnWidth)
                }
                .padding(.horizontal, spacing)
                .padding(.top, spacing)

                if isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
    }

    // MARK: - Columns

    private var leftIndices: [Int] {
        stride(from: 0, to: wallpapers.count, by: 2).map { $0 }
    }

    private var rightIndices: [Int] {
        stride(from: 1, to: wallpapers.count, by: 2).map { $0 }
    }

    @ViewBuilder
    private func columnWallpapers(_ indices: [Int], columnWidth: CGFloat) -> some View {
        LazyVStack(spacing: spacing) {
            ForEach(indices, id: \.self) { idx in
                let wallpaper = wallpapers[idx]
                let cellHeight = cellHeight(for: wallpaper, width: columnWidth)

                Button {
                    onSelect(wallpaper)
                } label: {
                    CellView(wallpaper: wallpaper)
                        .frame(width: columnWidth, height: cellHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if let contextMenu = contextMenu {
                        contextMenu(wallpaper)
                    }
                }
                .onAppear {
                    if idx >= wallpapers.count - 4, !isLoadingMore {
                        onLoadMore()
                    }
                }
            }
        }
        .frame(width: columnWidth)
    }

    private func cellHeight(for wallpaper: Wallpaper, width: CGFloat) -> CGFloat {
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
