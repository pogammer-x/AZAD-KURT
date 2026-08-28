import Foundation

struct POSFundingSource: Identifiable, Codable {
    var id = UUID()
    var companyID: UUID
    var amount: Double
}

struct POSTransaction: Identifiable, Codable {
    var id = UUID()
    
    var companyID: UUID
    var posBankID: UUID
    
    var customerName: String
    
    var principalAmount: Double
    var posAmount: Double
    
    var commissionRate: Double
    var commissionAmount: Double
    
    var netBankAmount: Double
    var grossProfitAmount: Double = 0
    var profitAmount: Double

    var fundingSources: [POSFundingSource] = []

    var fundingTotalAmount: Double {
        fundingSources.reduce(0) { $0 + $1.amount }
    }
    
    var installmentCount: Int
    
    var status: POSTransactionStatus
    
    var transactionDate: Date = Date()
    var settlementDate: Date?
    
    var note: String = ""

    private enum CodingKeys: String, CodingKey {
        case id, companyID, posBankID, customerName
        case principalAmount, posAmount, commissionRate, commissionAmount
        case netBankAmount, grossProfitAmount, profitAmount, fundingSources
        case installmentCount, status, transactionDate, settlementDate, note
    }

    init(
        id: UUID = UUID(), companyID: UUID, posBankID: UUID,
        customerName: String, principalAmount: Double, posAmount: Double,
        commissionRate: Double, commissionAmount: Double,
        netBankAmount: Double, grossProfitAmount: Double? = nil,
        profitAmount: Double, fundingSources: [POSFundingSource] = [],
        installmentCount: Int, status: POSTransactionStatus,
        transactionDate: Date = Date(), settlementDate: Date? = nil,
        note: String = ""
    ) {
        self.id = id
        self.companyID = companyID
        self.posBankID = posBankID
        self.customerName = customerName
        self.principalAmount = principalAmount
        self.posAmount = posAmount
        self.commissionRate = commissionRate
        self.commissionAmount = commissionAmount
        self.netBankAmount = netBankAmount
        self.grossProfitAmount = grossProfitAmount ?? (posAmount - principalAmount)
        self.profitAmount = profitAmount
        self.fundingSources = fundingSources
        self.installmentCount = installmentCount
        self.status = status
        self.transactionDate = transactionDate
        self.settlementDate = settlementDate
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        companyID = try container.decode(UUID.self, forKey: .companyID)
        posBankID = try container.decode(UUID.self, forKey: .posBankID)
        customerName = try container.decode(String.self, forKey: .customerName)
        principalAmount = try container.decode(Double.self, forKey: .principalAmount)
        posAmount = try container.decode(Double.self, forKey: .posAmount)
        commissionRate = try container.decode(Double.self, forKey: .commissionRate)
        commissionAmount = try container.decode(Double.self, forKey: .commissionAmount)
        netBankAmount = try container.decode(Double.self, forKey: .netBankAmount)
        grossProfitAmount = try container.decodeIfPresent(
            Double.self, forKey: .grossProfitAmount
        ) ?? (posAmount - principalAmount)
        profitAmount = try container.decode(Double.self, forKey: .profitAmount)
        fundingSources = try container.decodeIfPresent(
            [POSFundingSource].self, forKey: .fundingSources
        ) ?? []
        installmentCount = try container.decode(Int.self, forKey: .installmentCount)
        status = try container.decode(POSTransactionStatus.self, forKey: .status)
        transactionDate = try container.decode(Date.self, forKey: .transactionDate)
        settlementDate = try container.decodeIfPresent(Date.self, forKey: .settlementDate)
        note = try container.decode(String.self, forKey: .note)
    }
}

enum POSTransactionStatus: String, Codable {
    case pending
    case settled
    case cancelled
}
