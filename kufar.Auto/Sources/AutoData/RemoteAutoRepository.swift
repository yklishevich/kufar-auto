import Foundation
import AutoDomain
import Networking
import SharedKernel

package struct RemoteAutoRepository: AutoRepository {
    private let client: APIClient

    package init(client: APIClient) {
        self.client = client
    }

    package func listing(id: ListingID) async throws -> AutoListing {
        _ = try? await client.get("auto/\(id.rawValue)")
        return Self.Fixtures.listing(id: id)
    }
}

extension RemoteAutoRepository {
    enum Fixtures {
        static let dealer = Seller(id: "d-12", name: "АвтоЦентр на Кольцевой",
                                   rating: 4.5, isCompany: true)

        /// Та же схема, что у товаров, — другой набор полей.
        /// Различие между вертикалями сжимается до JSON.
        static let attributes = Data("""
        [
          { "id": "year",     "title": "Год выпуска", "type": "number", "value": 2016 },
          { "id": "mileage",  "title": "Пробег",      "type": "number", "value": 120000, "unit": "км" },
          { "id": "engine",   "title": "Двигатель",   "type": "text",   "value": "1.4 TSI, бензин" },
          { "id": "gearbox",  "title": "Коробка",     "type": "reference", "value": "DSG-7" },
          { "id": "customs",  "title": "Растаможен",  "type": "toggle", "value": true },
          { "id": "eco",      "title": "Эко-класс",   "type": "gauge",  "value": 5 }
        ]
        """.utf8)

        static func listing(id: ListingID) -> AutoListing {
            AutoListing(
                id: id,
                title: "Volkswagen Golf VII, 2016",
                price: Money(amount: 34_500),
                photoCount: 6,
                seller: dealer,
                isPromoted: false,
                attributesJSON: attributes,
                vin: "WVWZZZ1KZAW000001",
                owners: [
                    OwnerRecord(id: "o1", period: "2016 – 2019", mileage: 61_000),
                    OwnerRecord(id: "o2", period: "2019 – 2024", mileage: 59_000)
                ],
                hasDealerWarranty: true
            )
        }
    }
}
