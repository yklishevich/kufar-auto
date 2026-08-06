import Foundation
import SharedKernel

public enum AutoRoute: Hashable, Codable, Sendable, CaseIterable {
    case details(ListingID)
    case dealer(User.ID)

    public static var allCases: [AutoRoute] {
        [.details(ListingID("sample")), .dealer("sample")]
    }
}
