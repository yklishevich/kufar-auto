import SwiftUI
import Observation
import AutoDomain
import AutoInterface
import SearchInterface
import ProfileInterface
import AnalyticsAPI
import Navigation
import SchemaKit
import ListingKit
import DesignComponents
import DesignTokens
import SharedKernel

@MainActor
@Observable
final class AutoDetailModel {
    private let repo: any AutoRepository
    private let analytics: any AnalyticsTracking

    let id: ListingID
    private(set) var state: LoadState<AutoListing> = .loading
    private(set) var attributes: [SchemaField] = []

    init(id: ListingID, repo: any AutoRepository, analytics: any AnalyticsTracking) {
        self.id = id
        self.repo = repo
        self.analytics = analytics
    }

    func load() async {
        state = .loading
        do {
            let loaded = try await repo.listing(id: id)
            // Поломка схемы деградирует блок атрибутов, а не карточку,
            // и не молчит — событие уходит в мониторинг. См. GoodsDetailModel.
            do {
                attributes = try JSONDecoder().decode([SchemaField].self, from: loaded.attributesJSON)
            } catch {
                attributes = []
                analytics.track(.schemaDecodeFailed(id: id, vertical: .auto))
            }
            state = .loaded(loaded)
            analytics.track(.listingOpened(id: id, vertical: .auto))
        } catch {
            state = .failed
        }
    }

    func contactTapped() {
        analytics.track(.contactRequested(id: id))
    }
}

/// Карточка авто — двести строк композиции, а не копия экрана.
///
/// Галерея, ценник, панель контакта, блок продавца и продвижение
/// не продублированы: они в ListingKit. Здесь только то, чего нет
/// у других вертикалей.
struct AutoDetailScreen: View {
    @Environment(Router.self) private var router
    @State private var model: AutoDetailModel

    init(id: ListingID, repo: any AutoRepository, analytics: any AnalyticsTracking) {
        _model = State(wrappedValue: AutoDetailModel(id: id, repo: repo, analytics: analytics))
    }

    var body: some View {
        content
            .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let listing):
            card(for: listing)
        case .failed:
            ErrorStateView(message: "Не удалось загрузить объявление") {
                Task { await model.load() }
            }
        }
    }

    private func card(for listing: AutoListing) -> some View {
        ListingDetailScaffold(
            header: ListingHeader(
                id: listing.id,
                title: listing.title,
                price: listing.price,
                photoCount: listing.photoCount,
                seller: listing.seller,
                isPromoted: listing.isPromoted
            ),
            onSellerTap: {
                if listing.seller.isCompany {
                    router.push(AutoRoute.dealer(listing.seller.id))
                } else {
                    router.push(ProfileRoute.profile(listing.seller.id))
                }
            },
            onContact: { model.contactTapped() },
            attributes: {
                SchemaSection(fields: model.attributes)
            },
            extras: {
                // Тип слота Extras выводится здесь:
                // TupleView<(VINReportCard, OwnersHistory,
                //            _ConditionalContent<DealerWarrantyBanner, EmptyView>)>
                VINReportCard(vin: listing.vin)
                OwnersHistory(records: listing.owners)
                if listing.hasDealerWarranty {
                    DealerWarrantyBanner()
                }
            }
        )
    }
}

struct VINReportCard: View {
    let vin: String
    // @State внутри слота переживает обновления модели — именно потому,
    // что тип слота конкретный. С AnyView раскрытая секция схлопывалась бы
    // при каждой смене типа в коробке.
    @State private var isExpanded = false

    var body: some View {
        SectionCard {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Text("Проверка по VIN").font(Typography.title)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                LabeledRow(title: "VIN", value: vin)
                LabeledRow(title: "Залог", value: "Не найден")
                LabeledRow(title: "ДТП", value: "Не найдены")
            }
        }
    }
}

struct OwnersHistory: View {
    let records: [OwnerRecord]

    var body: some View {
        SectionCard {
            Text("История владельцев").font(Typography.title)
            ForEach(records) { record in
                LabeledRow(title: record.period, value: "\(record.mileage) км")
            }
        }
    }
}

struct DealerWarrantyBanner: View {
    var body: some View {
        SectionCard {
            Label("Гарантия дилера", systemImage: "checkmark.seal")
                .font(Typography.title)
                .foregroundStyle(Palette.accent)
        }
    }
}

struct DealerScreen: View {
    @Environment(Router.self) private var router
    private let dealerID: User.ID

    init(dealerID: User.ID) {
        self.dealerID = dealerID
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                SectionCard {
                    Text("Дилер \(dealerID)").font(Typography.title)
                    LabeledRow(title: "Проверенный продавец", value: "Да")
                }
                Button {
                    router.push(SearchRoute.sellerListings(dealerID))
                } label: {
                    SectionCard {
                        HStack {
                            Text("Все объявления дилера").font(Typography.title)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Palette.secondaryText)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(Spacing.l)
        }
        .navigationTitle("Дилер")
    }
}
