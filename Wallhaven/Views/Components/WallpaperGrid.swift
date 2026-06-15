import SwiftUI

/// 可复用的壁纸网格，带无限滚动触发
struct WallpaperGrid: View {
    let wallpapers: [Wallpaper]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onSelect: (Wallpaper) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(wallpapers) { wallpaper in
                    Button {
                        onSelect(wallpaper)
                    } label: {
                        WallpaperCell(wallpaper: wallpaper)
                            .aspectRatio(wallpaper.isPortrait ? 2/3 : 16/9, contentMode: .fit)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        // 当最后 4 张出现时触发加载更多
                        if wallpaper.id == wallpapers.dropLast(4).last?.id {
                            onLoadMore()
                        }
                    }
                }

                if isLoadingMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .gridCellColumns(2)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
    }
}

#Preview {
    WallpaperGrid(
        wallpapers: [.preview, .preview, .preview],
        isLoadingMore: false,
        onLoadMore: {},
        onSelect: { _ in }
    )
}
