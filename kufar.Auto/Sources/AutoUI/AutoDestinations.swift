import SwiftUI
import AutoDomain
import AutoInterface
import AnalyticsAPI

package struct AutoDestinations: ViewModifier {
    private let repo: any AutoRepository
    private let analytics: any AnalyticsTracking

    package init(repo: any AutoRepository, analytics: any AnalyticsTracking) {
        self.repo = repo
        self.analytics = analytics
    } 

    package func body(content: Content) -> some View {
        content.navigationDestination(for: AutoRoute.self) { route in
            switch route {
            case .details(let id):
                AutoDetailScreen(id: id, repo: repo, analytics: analytics)
            case .dealer(let dealerID):
                DealerScreen(dealerID: dealerID)
            }
        }
    }
}
