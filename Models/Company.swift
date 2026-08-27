import Foundation

struct Company: Identifiable, Codable {
    var id = UUID()
    var name: String
    var isActive: Bool = true
    var createdAt: Date = Date()
}
var totalPOSAmount: Double = 0
var totalBankDeduction: Double = 0
var netBalance: Double = 0
var pendingPOSAmount: Double = 0
