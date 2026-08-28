import Foundation

struct Payment: Identifiable, Codable {
    var id: UUID
    var companyID: UUID
    var receivableID: UUID
    var payerName: String
    var amount: Double
    var paymentDate: Date
    var paymentMethod: PaymentMethod
    var createdBy: String
    var note: String
    var createdAt: Date
    var isCancelled: Bool
    var cancelledBy: String?
    var cancelledAt: Date?

    init(
        id: UUID = UUID(),
        companyID: UUID,
        receivableID: UUID,
        payerName: String,
        amount: Double,
        paymentDate: Date = Date(),
        paymentMethod: PaymentMethod,
        createdBy: String,
        note: String = "",
        createdAt: Date = Date(),
        isCancelled: Bool = false,
        cancelledBy: String? = nil,
        cancelledAt: Date? = nil
    ) {
        self.id = id
        self.companyID = companyID
        self.receivableID = receivableID
        self.payerName = payerName
        self.amount = MoneyMath.rounded(amount)
        self.paymentDate = paymentDate
        self.paymentMethod = paymentMethod
        self.createdBy = createdBy
        self.note = note
        self.createdAt = createdAt
        self.isCancelled = isCancelled
        self.cancelledBy = cancelledBy
        self.cancelledAt = cancelledAt
    }

    private enum CodingKeys: String, CodingKey {
        case id, companyID, receivableID, payerName, amount, paymentDate
        case paymentMethod, createdBy, note, createdAt
        case isCancelled, cancelledBy, cancelledAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        companyID = try values.decode(UUID.self, forKey: .companyID)
        receivableID = try values.decode(UUID.self, forKey: .receivableID)
        payerName = try values.decode(String.self, forKey: .payerName)
        amount = MoneyMath.rounded(try values.decode(Double.self, forKey: .amount))
        paymentDate = try values.decodeIfPresent(Date.self, forKey: .paymentDate) ?? Date()
        paymentMethod = try values.decode(PaymentMethod.self, forKey: .paymentMethod)
        createdBy = try values.decodeIfPresent(String.self, forKey: .createdBy) ?? ""
        note = try values.decodeIfPresent(String.self, forKey: .note) ?? ""
        createdAt = try values.decodeIfPresent(Date.self, forKey: .createdAt) ?? paymentDate
        isCancelled = try values.decodeIfPresent(Bool.self, forKey: .isCancelled) ?? false
        cancelledBy = try values.decodeIfPresent(String.self, forKey: .cancelledBy)
        cancelledAt = try values.decodeIfPresent(Date.self, forKey: .cancelledAt)
    }
}

enum PaymentMethod: String, Codable {
    case cash
    case bankTransfer
    case card
    case other
}
