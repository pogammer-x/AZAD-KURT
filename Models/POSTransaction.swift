import Foundation

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
    var profitAmount: Double
    
    var installmentCount: Int
    
    var status: POSTransactionStatus
    
    var transactionDate: Date = Date()
    var settlementDate: Date?
    
    var note: String = ""
}

enum POSTransactionStatus: String, Codable {
    case pending
    case settled
    case cancelled
}
