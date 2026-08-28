import Foundation

struct Invoice: Identifiable, Codable {
    var id = UUID()
    var companyID: UUID
    var periodStart: Date
    var periodEnd: Date
    var grossPOSAmount: Double
    var principalAmount: Double
    var commissionAmount: Double
    var netPOSAmount: Double
    var settledAmount: Double
    var pendingAmount: Double
    var netProfitAmount: Double
    var transactionCount: Int
    var cancelledTransactionCount: Int
    var status: InvoiceStatus = .draft
    var invoiceDate: Date?
    var invoiceNumber: String?
    var note: String = ""
    var isLocked: Bool = false
    var lockedAt: Date?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

enum InvoiceStatus: String, Codable {
    case draft
    case invoiced
    case cancelled
}
