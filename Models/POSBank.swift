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
    
    // Seçilen taksit sayısına göre oranı verir
    func rate(for installmentCount: Int) -> Double {
        
        if installmentCount <= 1 {
            return singlePaymentRate
        }
        
        return installmentRates[installmentCount] ?? 0
    }
}
