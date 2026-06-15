import SwiftUI

/// 通用错误状态视图
struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("加载失败", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
                .multilineTextAlignment(.center)
        } actions: {
            Button("重试", action: retryAction)
                .buttonStyle(.bordered)
        }
    }
}

/// 空结果状态视图
struct EmptyResultView: View {
    var message: String = "没有找到相关壁纸"

    var body: some View {
        ContentUnavailableView(
            message,
            systemImage: "photo.on.rectangle.angled",
            description: Text("尝试使用不同的关键词或筛选条件")
        )
    }
}

#Preview {
    ErrorView(message: "网络连接超时，请检查网络后重试") {}
}
