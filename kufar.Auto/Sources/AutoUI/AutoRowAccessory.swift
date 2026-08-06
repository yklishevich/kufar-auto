import SwiftUI
import AutoDomain
import DesignTokens
import SharedKernel

/// Акцессорная строка авто внутри ОБЩЕЙ ленты.
///
/// Живёт в вертикали, но рисуется в чужом экране: `Search` не знает этого типа
/// и не может его импортировать. Вью приезжает фабрикой из composition root —
/// тот же приём, что с destinations, только вместо маршрута передаётся слот.
///
/// Внутри — вычисление, а не поле схемы. Если бы здесь было «2015 · 120 000 км»,
/// слот был бы не нужен: это данные, их рисует общий рендерер.
///
/// # Здесь нельзя заводить состояние, и это не стилистика
///
/// Вью попадает в ленту через `ListingRowAccessory`, а он стирает тип в `AnyView`.
/// Стирание там допустимо ровно потому, что в коробке терять нечего: сейчас
/// внутри `Label`, посчитанный из цены. Добавь сюда `@State`, `AsyncImage`,
/// анимацию или фокус ввода — и SwiftUI начнёт сносить поддерево при каждой
/// смене типа в коробке. Проявится это как «иногда само схлопывается» на чужом
/// экране, у чужой команды, и связать симптом с этим файлом будет некому.
///
/// Обходить нельзя — надо снимать коробку: `ListingRowAccessory` заменяется
/// дженериком `Accessory: View` в `SearchScreen`, `FavoritesScreen`,
/// `SearchDestinations` и трёх функциях `SearchAssembly`. Цена посчитана
/// в комментарии к `ListingRowAccessory`. Это PR в чужой репозиторий, поэтому
/// договариваться надо до того, как состояние добавлено, а не после.
package struct AutoRowAccessory: View {
    private let price: Money

    package init(price: Money) {
        self.price = price
    }

    package var body: some View {
        Label(
            "от \(AutoCredit.monthlyPayment(for: price).formatted) в месяц",
            systemImage: "creditcard"
        )
        .font(Typography.caption)
        .foregroundStyle(Palette.secondaryText)
    }
}
