import SwiftUI
import AutoDomain
import PostingInterface
import CatalogContracts
import DesignTokens
import SharedKernel

/// Вклад вертикали в ЧУЖОЙ флоу подачи.
///
/// Живёт в `AutoUI`, рисуется внутри экрана команды подачи. `Posting` этого
/// типа не знает и импортировать его не может: он параметризован
/// `Step: View`, а конкретный тип подставляет composition root.
///
/// Почему это не поле схемы. «Марка» и «год» как вопросы формы — данные,
/// их задаёт бэкенд, кода не нужно. Здесь же пользователь вводит VIN,
/// а марка и год **выводятся** из него — это вычисление плюс взаимодействие
/// (в проде ещё и камера). Схемой не выражается, значит слот.
package struct AutoPostingStep: View {
    private let category: CatalogCategory
    @Binding private var draft: PostingDraft

    // @State шага. Живёт ровно столько, сколько живёт поддерево: сменил
    // категорию на «Квартиры» — тип в _ConditionalContent изменился,
    // поддерево снесено, введённый VIN исчез. Здесь это правильно.
    @State private var vin = ""
    @State private var isDecoding = false
    @State private var failed = false

    package init(category: CatalogCategory, draft: Binding<PostingDraft>) {
        self.category = category
        _draft = draft
    }

    package var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Данные автомобиля")
                .font(Typography.title)

            Text("Заполним марку и год по VIN — их не придётся вводить руками.")
                .font(Typography.caption)
                .foregroundStyle(Palette.secondaryText)

            TextField("VIN, 17 символов", text: $vin)
                .font(.body.monospaced())

            Button {
                Task { await fill() }
            } label: {
                Label(isDecoding ? "Распознаём…" : "Заполнить по VIN",
                      systemImage: "doc.text.viewfinder")
            }
            .disabled(vin.count < 10 || isDecoding)

            if failed {
                Text("Не удалось разобрать VIN — проверьте символы.")
                    .font(Typography.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private func fill() async {
        isDecoding = true
        failed = false
        defer { isDecoding = false }
        // В проде — запрос в справочник; здесь разбор по правилам самого VIN.
        try? await Task.sleep(for: .milliseconds(400))

        guard let decoded = VINDecoder.decode(vin) else {
            failed = true
            return
        }

        // Пишем в общий черновик: дальше он публикуется тем же кодом подачи,
        // что и черновик пылесоса. Вертикаль добавляет данные, а не свой флоу.
        draft.title = decoded.title
        draft.values["brand"] = .text(decoded.brand)
        draft.values["year"] = .number(Double(decoded.year))
        draft.values["vin"] = .text(vin.uppercased())
    }
}
