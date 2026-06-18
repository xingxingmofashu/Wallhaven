import SwiftUI

/// Single wallpaper thumbnail card
struct CellView: View {
    let wallpaper: Wallpaper

    var body: some View {
        CacheAsyncImage(url: wallpaper.thumbnailURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
        }
    }

}

// MARK: - Preview

#Preview {
    CellView(wallpaper: .preview)
        .frame(width: 180, height: 120)
        .padding()
}
