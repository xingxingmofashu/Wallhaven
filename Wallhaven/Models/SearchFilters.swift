import Foundation

// MARK: - Search Filters

/// 搜索筛选条件，绑定到 SearchViewModel
struct SearchFilters: Equatable {

    var query: String = ""

    // categories: 每位对应 general / anime / people，1=开 0=关
    var general: Bool = true
    var anime: Bool   = true
    var people: Bool  = true

    // purity: 每位对应 sfw / sketchy / nsfw
    var sfw: Bool     = true
    var sketchy: Bool = false
    var nsfw: Bool    = false

    var sorting: Sorting     = .dateAdded
    var order: Order         = .desc
    var topRange: TopRange   = .oneMonth

    var atleast: String      = ""     // e.g. "1920x1080"
    var resolutions: String  = ""     // 逗号分隔 e.g. "1920x1080,2560x1440"
    var ratios: String       = ""     // 逗号分隔 e.g. "16x9,16x10"
    var colors: String       = ""     // 单色 hex e.g. "ff0000"
    var seed: String?                  // 随机排序时的 seed

    // MARK: - Enums

    enum Sorting: String, CaseIterable, Identifiable {
        case dateAdded  = "date_added"
        case relevance  = "relevance"
        case random     = "random"
        case views      = "views"
        case favorites  = "favorites"
        case toplist    = "toplist"
        case hot        = "hot"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .dateAdded:  return "最新"
            case .relevance:  return "相关"
            case .random:     return "随机"
            case .views:      return "浏览量"
            case .favorites:  return "收藏量"
            case .toplist:    return "排行榜"
            case .hot:        return "热门"
            }
        }
    }

    enum Order: String, CaseIterable, Identifiable {
        case desc = "desc"
        case asc  = "asc"
        var id: String { rawValue }
        var displayName: String { self == .desc ? "降序" : "升序" }
    }

    enum TopRange: String, CaseIterable, Identifiable {
        case oneDay    = "1d"
        case threeDays = "3d"
        case oneWeek   = "1w"
        case oneMonth  = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear   = "1y"
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .oneDay:      return "今日"
            case .threeDays:   return "近3天"
            case .oneWeek:     return "近一周"
            case .oneMonth:    return "近一月"
            case .threeMonths: return "近三月"
            case .sixMonths:   return "近半年"
            case .oneYear:     return "近一年"
            }
        }
    }

    // MARK: - Computed API Parameters

    /// 三位二进制字符串，例如 "111", "100"
    var categoriesParam: String {
        "\(general ? 1 : 0)\(anime ? 1 : 0)\(people ? 1 : 0)"
    }

    var purityParam: String {
        "\(sfw ? 1 : 0)\(sketchy ? 1 : 0)\(nsfw ? 1 : 0)"
    }

    /// 将当前 filters 转为 URL query items
    func queryItems(page: Int) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if !query.isEmpty {
            items.append(URLQueryItem(name: "q", value: query))
        }

        items.append(URLQueryItem(name: "categories", value: categoriesParam))
        items.append(URLQueryItem(name: "purity",     value: purityParam))
        items.append(URLQueryItem(name: "sorting",    value: sorting.rawValue))
        items.append(URLQueryItem(name: "order",      value: order.rawValue))

        if sorting == .toplist {
            items.append(URLQueryItem(name: "topRange", value: topRange.rawValue))
        }

        if !atleast.isEmpty {
            items.append(URLQueryItem(name: "atleast", value: atleast))
        }
        if !resolutions.isEmpty {
            items.append(URLQueryItem(name: "resolutions", value: resolutions))
        }
        if !ratios.isEmpty {
            items.append(URLQueryItem(name: "ratios", value: ratios))
        }
        if !colors.isEmpty {
            items.append(URLQueryItem(name: "colors", value: colors))
        }
        if sorting == .random, let seed = seed {
            items.append(URLQueryItem(name: "seed", value: seed))
        }

        items.append(URLQueryItem(name: "page", value: "\(page)"))

        return items
    }
}

// MARK: - Available Colors

struct WallhavenColor: Identifiable, Hashable {
    let hex: String   // 不含 #
    var id: String { hex }
    var display: String { "#\(hex)" }
}

extension WallhavenColor {
    static let all: [WallhavenColor] = [
        "660000","990000","cc0000","cc3333","ea4c88",
        "993399","663399","333399","0066cc","0099cc",
        "66cccc","77cc33","669900","336600","666600",
        "999900","cccc33","ffff00","ffcc33","ff9900",
        "ff6600","cc6633","996633","663300","000000",
        "999999","cccccc","ffffff","424153"
    ].map { WallhavenColor(hex: $0) }
}
