import Foundation

struct Transaction: Identifiable, Codable {
    var id = UUID()
    
    // Hangi şirkete ait?
    var companyID: UUID
    
    // İşlem türü
    var type: TransactionType
    
    // İşlem başlığı
    var title: String
    
    // Açıklama
    var note: String = ""
    
    // Kasaya giren / çıkan tutar
    var amount: Double
    
    // İşlem tarihi
    var transactionDate: Date = Date()
    
    // İlgili POS işlemi varsa
    var posTransactionID: UUID?
    
    // İlgili alacak varsa
    var receivableID: UUID?
    
    // İlgili ödeme varsa
    var paymentID: UUID?
    
    // İşlemi yapan kullanıcı
    var createdBy: String
    
    // Oluşturulma zamanı
    var createdAt: Date = Date()
}

enum TransactionType: String, Codable {
    case income
    case expense
    case posSettlement
    case receivableCollection
    case commission
    case adjustment
}
