import SwiftUI

/// 可复用的壁纸网格，双列瀑布流（每张图按真实宽高比显示，无空白）
struct WallpaperGrid: View {
    let wallpapers: [Wallpaper]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onSelect: (Wallpaper) -> Void

    private let spacing: CGFloat = 8

    // 将 wallpapers 按奇偶下标分到左右两列
    private var leftColumn: [Wallpaper] {
        wallpapers.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
    }
    private var rightColumn: [Wallpaper] {
        wallpapers.enumerated().filter { $0.offset % 2 == 1 }.map(\.element)
    }

    var body: some View {
        GeometryReader { geo in
            // 屏幕宽 - 左右边距(8+8) - 中间间距(8)，平分两列
            let columnWidth = (geo.size.width - spacing * 3) / 2
            ScrollView {
                HStack(alignment: .top, spacing: spacing) {
                    masonryColumn(wallpapers: leftColumn, width: columnWidth)
                    masonryColumn(wallpapers: rightColumn, width: columnWidth)
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

    // MARK: - Single column

    @ViewBuilder
    private func masonryColumn(wallpapers: [Wallpaper], width: CGFloat) -> some View {
        LazyVStack(spacing: spacing) {
            ForEach(wallpapers) { wallpaper in
                Button {
                    onSelect(wallpaper)
                } label: {
                    WallpaperCell(wallpaper: wallpaper)
                        .frame(width: width,
                               height: width / CGFloat(wallpaper.aspectRatio))
                }
                .buttonStyle(.plain)
                .onAppear {
                    if wallpaper.id == wallpapers.dropLast(4).last?.id {
                        onLoadMore()
                    }
                }
            }
        }
        .frame(width: width)
    }
}

#Preview {
    WallpaperGrid(
        wallpapers: [.preview, .preview, .preview, .preview],
        isLoadingMore: false,
        onLoadMore: {},
        onSelect: { _ in }
    )
}
