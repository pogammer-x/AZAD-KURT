import Foundation

struct BalanceTransaction: Identifiable, Codable {
    var id = UUID()
    var companyID: UUID
    var amount: Double
    var type: BalanceTransactionType
    var date: Date = Date()
    var description: String
    var relatedPOSTransactionID: UUID?
    var posBankID: UUID?
    var oldBalance: Double
    var newBalance: Double
    var createdBy: String?
    var modifiedBy: String?
    var modifiedAt: Date?
    var cancelledBy: String?
    var cancelledAt: Date?

    private enum CodingKeys: String, CodingKey {
        case id, companyID, amount, type, date, description
        case relatedPOSTransactionID, posBankID, oldBalance, newBalance
        case createdBy, modifiedBy, modifiedAt, cancelledBy, cancelledAt
    }

    init(
        id: UUID = UUID(),
        companyID: UUID,
        amount: Double,
        type: BalanceTransactionType,
        date: Date = Date(),
        description: String,
        relatedPOSTransactionID: UUID? = nil,
        posBankID: UUID? = nil,
        oldBalance: Double,
        newBalance: Double,
        createdBy: String? = nil,
        modifiedBy: String? = nil,
        modifiedAt: Date? = nil,
        cancelledBy: String? = nil,
        cancelledAt: Date? = nil
    ) {
        self.id = id
        self.companyID = companyID
        self.amount = MoneyMath.rounded(amount)
        self.type = type
        self.date = date
        self.description = description
        self.relatedPOSTransactionID = relatedPOSTransactionID
        self.posBankID = posBankID
        self.oldBalance = MoneyMath.rounded(oldBalance)
        self.newBalance = MoneyMath.rounded(newBalance)
        self.createdBy = createdBy
        self.modifiedBy = modifiedBy
        self.modifiedAt = modifiedAt
        self.cancelledBy = cancelledBy
        self.cancelledAt = cancelledAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        companyID = try container.decode(UUID.self, forKey: .companyID)
        amount = MoneyMath.rounded(try container.decode(Double.self, forKey: .amount))
        type = try container.decode(BalanceTransactionType.self, forKey: .type)
        date = try container.decode(Date.self, forKey: .date)
        description = try container.decode(String.self, forKey: .description)
        relatedPOSTransactionID = try container.decodeIfPresent(UUID.self, forKey: .relatedPOSTransactionID)
        posBankID = try container.decodeIfPresent(UUID.self, forKey: .posBankID)
        oldBalance = MoneyMath.rounded(try container.decode(Double.self, forKey: .oldBalance))
        newBalance = MoneyMath.rounded(try container.decode(Double.self, forKey: .newBalance))
        createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        modifiedBy = try container.decodeIfPresent(String.self, forKey: .modifiedBy)
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt)
        cancelledBy = try container.decodeIfPresent(String.self, forKey: .cancelledBy)
        cancelledAt = try container.decodeIfPresent(Date.self, forKey: .cancelledAt)
    }
}

enum BalanceTransactionType: String, Codable {
    case manualAdjustment
    case capitalContribution
    case capitalWithdrawal
    case income
    case expense
    case posPrincipalDebit
    case posPrincipalRefund
    case posSettlementCredit
}

enum FinancialOperationResult: Equatable {
    case success
    case failure(String)
}
