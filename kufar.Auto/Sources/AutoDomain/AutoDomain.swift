import Foundation
import SharedKernel

public struct AutoListing: Identifiable, Hashable, Sendable {
    public let id: ListingID
    public let title: String
    public let price: Money
    public let photoCount: Int
    public let seller: Seller
    public let isPromoted: Bool
    public let attributesJSON: Data
    // Вертикально-специфичное: это настоящая логика, она никуда не денется
    // и её место — рядом со своим доменом, а не в общем каркасе.
    public let vin: String
    public let owners: [OwnerRecord]
    public let hasDealerWarranty: Bool

    public init(
        id: ListingID,
        title: String,
        price: Money,
        photoCount: Int,
        seller: Seller,
        isPromoted: Bool,
        attributesJSON: Data,
        vin: String,
        owners: [OwnerRecord],
        hasDealerWarranty: Bool
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.photoCount = photoCount
        self.seller = seller
        self.isPromoted = isPromoted
        self.attributesJSON = attributesJSON
        self.vin = vin
        self.owners = owners
        self.hasDealerWarranty = hasDealerWarranty
    }
}

public struct OwnerRecord: Identifiable, Hashable, Sendable {
    public let id: String
    public let period: String
    public let mileage: Int

    public init(id: String, period: String, mileage: Int) {
        self.id = id
        self.period = period
        self.mileage = mileage
    }
}

/// Ленты нет: она общая и живёт в поиске.
public protocol AutoRepository: Sendable {
    func listing(id: ListingID) async throws -> AutoListing
}

/// Прикидка платежа по автокредиту.
///
/// Это и есть граница между «схемой» и «слотом»: пробег и год выпуска —
/// **данные**, они приезжают полем схемы и рисуются общим рендерером без единой
/// строчки кода вертикали. Платёж — **вычисление** над ценой, схемой его
/// не выразить. Ровно поэтому строка ленты у авто получает слот, а у товаров
/// не получает ничего: у товаров в строке считать нечего.
///
/// Живёт в домене, а не в UI: ставка и срок — предмет продуктовых решений
/// и A/B-тестов, а не вёрстки.
/// Разбор VIN — вторая вертикально-специфичная вычислялка, и самый чистый
/// пример границы «схема против слота». Марка и год выпуска как **поля** —
/// это схема: бэкенд их знает, клиенту рисовать нечего. Марка и год,
/// **выведенные из введённой строки**, — это код, и он может жить только
/// в вертикали.
package enum VINDecoder {
    package struct Decoded: Hashable, Sendable {
        package let brand: String
        package let year: Int

        package var title: String { "\(brand), \(year)" }
    }

    /// World Manufacturer Identifier — первые три символа. Настоящий реестр,
    /// просто урезанный до четырёх записей.
    private static let manufacturers: [String: String] = [
        "WVW": "Volkswagen",
        "WBA": "BMW",
        "XTA": "Lada",
        "JHM": "Honda"
    ]

    /// Позиция 10 — код модельного года. Таблица настоящая: буквы идут
    /// без I, O, Q, U и Z, потому что их путают с цифрами.
    private static let modelYears: [Character: Int] = {
        var table: [Character: Int] = [:]
        for (offset, symbol) in Array("ABCDEFGHJKLMNPRSTVWXY").enumerated() {
            table[symbol] = 2010 + offset
        }
        for (offset, symbol) in Array("123456789").enumerated() {
            table[symbol] = 2001 + offset
        }
        return table
    }()

    package static func decode(_ vin: String) -> Decoded? {
        let symbols = Array(vin.uppercased())
        guard symbols.count >= 10 else { return nil }
        let wmi = String(symbols.prefix(3))
        guard let brand = manufacturers[wmi], let year = modelYears[symbols[9]] else { return nil }
        return Decoded(brand: brand, year: year)
    }
}

package enum AutoCredit {
    package static let defaultTermMonths = 60
    package static let annualRate = 0.149

    package static func monthlyPayment(for price: Money, months: Int = defaultTermMonths) -> Money {
        let principal = NSDecimalNumber(decimal: price.amount).doubleValue
        let monthlyRate = annualRate / 12
        let growth = pow(1 + monthlyRate, Double(months))
        let payment = principal * monthlyRate * growth / (growth - 1)
        return Money(amount: Decimal(payment.rounded()), currency: price.currency)
    }
}
