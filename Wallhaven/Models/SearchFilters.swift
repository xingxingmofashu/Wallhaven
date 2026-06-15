import Foundation

// MARK: - Search Filters

/// Search filter criteria, bound to SearchViewModel
struct SearchFilters: Equatable {

    var query: String = ""

    // categories: each bit corresponds to general / anime / people, 1=on 0=off
    var general: Bool = true
    var anime: Bool   = true
    var people: Bool  = true

    // purity: each bit corresponds to sfw / sketchy / nsfw
    var sfw: Bool     = true
    var sketchy: Bool = false
    var nsfw: Bool    = false

    var sorting: Sorting     = .dateAdded
    var order: Order         = .desc
    var topRange: TopRange   = .oneMonth

    var atleast: String      = ""     // e.g. "1920x1080"
    var resolutions: String  = ""     // comma-separated e.g. "1920x1080,2560x1440"
    var ratios: String       = ""     // comma-separated e.g. "16x9,16x10"
    var selectedColor: String  = ""     // single color hex e.g. "ff0000"
    var seed: String?                  // seed for random sorting

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
            case .dateAdded:  return "Latest"
            case .relevance:  return "Relevance"
            case .random:     return "Random"
            case .views:      return "Views"
            case .favorites:  return "Favorites"
            case .toplist:    return "Toplist"
            case .hot:        return "Hot"
            }
        }
    }

    enum Order: String, CaseIterable, Identifiable {
        case desc = "desc"
        case asc  = "asc"
        var id: String { rawValue }
        var displayName: String { self == .desc ? "Descending" : "Ascending" }
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
            case .oneDay:      return "Today"
            case .threeDays:   return "Last 3 Days"
            case .oneWeek:     return "Last Week"
            case .oneMonth:    return "Last Month"
            case .threeMonths: return "Last 3 Months"
            case .sixMonths:   return "Last 6 Months"
            case .oneYear:     return "Last Year"
            }
        }
    }

    // MARK: - Computed API Parameters

    /// Three-bit binary string, e.g. "111", "100"
    var categoriesParam: String {
        "\(general ? 1 : 0)\(anime ? 1 : 0)\(people ? 1 : 0)"
    }

    var purityParam: String {
        "\(sfw ? 1 : 0)\(sketchy ? 1 : 0)\(nsfw ? 1 : 0)"
    }

    /// Convert current filters to URL query items
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
            items.append(URLQueryItem(name: "top_range", value: topRange.rawValue))
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
        if !selectedColor.isEmpty {
            items.append(URLQueryItem(name: "colors", value: selectedColor))
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
    let hex: String   // without #
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
