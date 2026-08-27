import Foundation

struct Payment: Identifiable, Codable {
    var id = UUID()
    
    // Hangi şirkete ait?
    var companyID: UUID
    
    // Hangi alacağa yapılan ödeme?
    var receivableID: UUID
    
    // Ödemeyi yapan kişi
    var payerName: String
    
    // Ödeme tutarı
    var amount: Double
    
    // Ödeme tarihi
    var paymentDate: Date = Date()
    
    // Ödeme yöntemi
    var paymentMethod: PaymentMethod
    
    // İşlemi sisteme giren kullanıcı
    var createdBy: String
    
    // Açıklama
    var note: String = ""
    
    var createdAt: Date = Date()
}

enum PaymentMethod: String, Codable {
    case cash
    case bankTransfer
    case card
    case other
}
