import SwiftUI
import Photos

@Observable
final class WallpaperDetailViewModel {

    // MARK: - State

    var wallpaper: Wallpaper
    var detailLoaded  = false          // 是否已加载带 tags 的完整详情
    var isLoadingDetail = false
    var isSaving      = false          // 保存到相册中
    var saveResult: SaveResult?

    enum SaveResult: Equatable {
        case success
        case failure(String)
    }

    // MARK: - Init

    init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
    }

    // MARK: - Load Detail（获取包含 tags 的完整数据）

    func loadDetailIfNeeded() {
        guard !detailLoaded, !isLoadingDetail else { return }
        isLoadingDetail = true
        Task {
            defer { isLoadingDetail = false }
            do {
                let full = try await WallhavenAPI.shared.wallpaper(id: wallpaper.id)
                wallpaper    = full
                detailLoaded = true
            } catch {
                // 加载失败静默处理，保留预览数据
            }
        }
    }

    // MARK: - Save to Photos

    func saveToPhotos() {
        guard let url = wallpaper.fullURL else {
            saveResult = .failure("无效的图片地址")
            return
        }
        isSaving = true
        saveResult = nil

        Task {
            defer { isSaving = false }
            do {
                // 下载原图
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    saveResult = .failure("图片数据无效")
                    return
                }

                // 请求相册权限
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    saveResult = .failure("需要相册权限，请在设置中开启")
                    return
                }

                // 存储
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                saveResult = .success
            } catch {
                saveResult = .failure("保存失败：\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Share

    var shareItems: [Any] {
        [wallpaper.url]
    }

    // MARK: - Formatted Info

    var formattedInfo: [(label: String, value: String)] {
        [
            ("分辨率", wallpaper.resolution),
            ("比例",   wallpaper.ratio),
            ("类型",   wallpaper.fileType),
            ("大小",   wallpaper.formattedFileSize),
            ("纯度",   wallpaper.purity.uppercased()),
            ("分类",   wallpaper.category.capitalized),
            ("浏览量", "\(wallpaper.views)"),
            ("收藏量", "\(wallpaper.favorites)"),
            ("上传于", wallpaper.createdAt),
        ]
    }
}
