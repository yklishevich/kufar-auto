import SwiftUI
import AutoData
import AutoDomain
import AutoUI
import AnalyticsAPI
import Networking
import SharedKernel
import PostingInterface
import CatalogContracts

public enum AutoAssembly {

    public static func makeRepository(client: APIClient) -> any AutoRepository {
        RemoteAutoRepository(client: client)
    }

    public static func makeDestinations(
        repo: any AutoRepository,
        analytics: any AnalyticsTracking
    ) -> some ViewModifier {
        AutoDestinations(repo: repo, analytics: analytics)
    }

    /// Вклад вертикали в строку ОБЩЕЙ ленты.
    ///
    /// Возвращает непрозрачный тип: корень подставит его в слот, но какой
    /// именно экран нарисуется — не узнает. `ListingRef` берётся из ядра,
    /// поэтому в сигнатуре нет ничего из `Search` — вертикаль по-прежнему
    /// не знает, кто её рисует.
    @MainActor
    public static func rowAccessory(for ref: ListingRef) -> some View {
        AutoRowAccessory(price: ref.price)
    }

    /// Вклад вертикали в чужой флоу подачи.
    ///
    /// Зависимость на `PostingInterface` и `CatalogContracts` — не горизонталь:
    /// оба пакета контрактные и лежат уровнем ниже вертикалей. Та же форма,
    /// что и зависимость на `SearchInterface` ради «объявлений дилера».
    @MainActor
    public static func postingStep(
        _ category: CatalogCategory,
        draft: Binding<PostingDraft>
    ) -> some View {
        AutoPostingStep(category: category, draft: draft)
    }
}
