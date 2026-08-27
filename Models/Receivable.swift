import Foundation

struct Receivable: Identifiable, Codable {
    var id = UUID()
    
    var companyID: UUID
    
    var debtorName: String
    var reason: String
    
    var principalAmount: Double
    var dailyInterestRate: Double
    
    var startDate: Date = Date()
    var dueDate: Date?
    
    var totalPaid: Double = 0
    
    var isCompoundInterest: Bool = true
    
    var status: ReceivableStatus = .active
    
    var note: String = ""
    
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

enum ReceivableStatus: String, Codable {
    case active
    case paid
    case overdue
    case cancelled
}
