import SwiftUI

struct DetailThumbnailView: View {
    let relatedWallpapers: [Wallpaper]
    let currentID: String?
    let favoritedIDs: Set<String>
    let selectedIndex: Int
    let onSelect: (Wallpaper) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(relatedWallpapers) { wallpaper in
                        Button {
                            onSelect(wallpaper)
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
                                if favoritedIDs.contains(wallpaper.id) {
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
                    if let id = currentID {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            .onAppear {
                if let id = currentID {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
    }
}
