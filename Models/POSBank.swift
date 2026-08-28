import Foundation

struct POSBank: Identifiable, Codable {
    
    var id = UUID()
    
    var companyID: UUID
    
    var bankName: String
    
    // Tek çekim oranı
    var singlePaymentRate: Double
    
    // 2 - 18 taksit oranları
    var installmentRates: [Int: Double]
    
    var isActive: Bool = true
    
    var createdAt: Date = Date()

    var balance: Double = 0
    
    // Seçilen taksit sayısına göre oranı verir
    func rate(for installmentCount: Int) -> Double {
        
        if installmentCount <= 1 {
            return singlePaymentRate
        }
        
        return installmentRates[installmentCount] ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case id, companyID, bankName, singlePaymentRate
        case installmentRates, isActive, createdAt, balance
    }

    init(
        id: UUID = UUID(),
        companyID: UUID,
        bankName: String,
        singlePaymentRate: Double,
        installmentRates: [Int: Double],
        isActive: Bool = true,
        createdAt: Date = Date(),
        balance: Double = 0
    ) {
        self.id = id
        self.companyID = companyID
        self.bankName = bankName
        self.singlePaymentRate = singlePaymentRate
        self.installmentRates = installmentRates
        self.isActive = isActive
        self.createdAt = createdAt
        self.balance = balance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        companyID = try container.decode(UUID.self, forKey: .companyID)
        bankName = try container.decode(String.self, forKey: .bankName)
        singlePaymentRate = try container.decode(
            Double.self,
            forKey: .singlePaymentRate
        )
        installmentRates = try container.decode(
            [Int: Double].self,
            forKey: .installmentRates
        )
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        balance = try container.decodeIfPresent(
            Double.self,
            forKey: .balance
        ) ?? 0
    }
}
