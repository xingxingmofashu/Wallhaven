import SwiftUI

/// 可复用的壁纸网格，双列瀑布流（每张图按真实宽高比显示，无空白）
struct WallpaperGrid: View {
    let wallpapers: [Wallpaper]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onSelect: (Wallpaper) -> Void

    // 将 wallpapers 按奇偶下标分到左右两列
    private var leftColumn: [Wallpaper] {
        wallpapers.enumerated().filter { $0.offset % 2 == 0 }.map(\.element)
    }
    private var rightColumn: [Wallpaper] {
        wallpapers.enumerated().filter { $0.offset % 2 == 1 }.map(\.element)
    }

    var body: some View {
        ScrollView {
            GeometryReader { geo in
                let columnWidth = (geo.size.width - 8 * 3) / 2   // 两列宽，左右各 8pt 外边距 + 中间 8pt 间距
                let _ = columnWidth  // suppress unused warning
            }
            .frame(height: 0)   // 占位读宽，不占空间

            HStack(alignment: .top, spacing: 8) {
                masonryColumn(wallpapers: leftColumn)
                masonryColumn(wallpapers: rightColumn)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            if isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
    }

    // MARK: - Single column

    @ViewBuilder
    private func masonryColumn(wallpapers: [Wallpaper]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(wallpapers) { wallpaper in
                Button {
                    onSelect(wallpaper)
                } label: {
                    WallpaperCell(wallpaper: wallpaper)
                        .aspectRatio(wallpaper.aspectRatio, contentMode: .fit)
                }
                .buttonStyle(.plain)
                .onAppear {
                    // 任意一列中最后 4 张出现时触发加载更多
                    if wallpaper.id == wallpapers.dropLast(4).last?.id {
                        onLoadMore()
                    }
                }
            }
        }
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
