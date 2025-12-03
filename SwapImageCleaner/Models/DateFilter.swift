import Foundation

enum DateFilter: String, CaseIterable, Identifiable {
    case all
    case lastSevenDays
    case lastThirtyDays
    case thisYear
    case older

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "Tüm zamanlar"
        case .lastSevenDays:
            return "Son 7 gün"
        case .lastThirtyDays:
            return "Son 30 gün"
        case .thisYear:
            return "Bu yıl"
        case .older:
            return "Daha eski"
        }
    }

    var subtitle: String? {
        let currentYear = Calendar.current.component(.year, from: Date())
        switch self {
        case .all:
            return nil
        case .lastSevenDays:
            return "Geçtiğimiz hafta"
        case .lastThirtyDays:
            return "Son bir ay"
        case .thisYear:
            return "\(currentYear) boyunca"
        case .older:
            return "\(currentYear - 1) ve öncesi"
        }
    }

    func predicateReferenceDate() -> NSPredicate? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .all:
            return nil
        case .lastSevenDays:
            guard let start = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
            return NSPredicate(format: "creationDate >= %@", start as NSDate)
        case .lastThirtyDays:
            guard let start = calendar.date(byAdding: .day, value: -30, to: now) else { return nil }
            return NSPredicate(format: "creationDate >= %@", start as NSDate)
        case .thisYear:
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) else { return nil }
            return NSPredicate(format: "creationDate >= %@", startOfYear as NSDate)
        case .older:
            guard let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) else { return nil }
            return NSPredicate(format: "creationDate < %@", startOfYear as NSDate)
        }
    }
}
