import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteWallpaper.addedAt, order: .reverse)
    private var favorites: [FavoriteWallpaper]

    @State private var favVM            = FavoritesViewModel()
    @State private var selectedFavorite: FavoriteWallpaper?
    @State private var showDeleteAlert  = false

    private let columns = [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 8)]

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    emptyView
                } else {
                    gridView
                }
            }
            .navigationTitle("收藏")
            .toolbar {
                if !favorites.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
            .alert("清空收藏", isPresented: $showDeleteAlert) {
                Button("清空", role: .destructive) {
                    favVM.clearAll(context: modelContext)
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作将删除所有本地收藏，无法恢复。")
            }
        }
    }

    // MARK: - Grid

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(favorites) { fav in
                    FavoriteCell(favorite: fav)
                        .aspectRatio(16/9, contentMode: .fit)
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(fav)
                                try? modelContext.save()
                            } label: {
                                Label("取消收藏", systemImage: "heart.slash")
                            }
                        }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
        }
    }

    // MARK: - Empty

    private var emptyView: some View {
        ContentUnavailableView(
            "还没有收藏",
            systemImage: "heart",
            description: Text("在壁纸详情页点击「收藏」，壁纸将保存在这里")
        )
    }
}

// MARK: - FavoriteCell

struct FavoriteCell: View {
    let favorite: FavoriteWallpaper

    var body: some View {
        CachedAsyncImage(url: favorite.thumbnailURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Rectangle()
                .fill(Color(.systemGray5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .bottomLeading) {
            HStack(spacing: 4) {
                PurityBadge(purity: favorite.purity)
                CategoryBadge(category: favorite.category)
            }
            .padding(6)
        }
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: FavoriteWallpaper.self, inMemory: true)
}
