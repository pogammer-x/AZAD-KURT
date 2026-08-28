import Foundation

enum MoneyMath {
    static func rounded(_ value: Double) -> Double {
        let number = NSDecimalNumber(value: value)
        let behavior = NSDecimalNumberHandler(
            roundingMode: .bankers,
            scale: 2,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        return number.rounding(accordingToBehavior: behavior).doubleValue
    }

    static func add(_ lhs: Double, _ rhs: Double) -> Double {
        rounded(lhs + rhs)
    }

    static func subtract(_ lhs: Double, _ rhs: Double) -> Double {
        rounded(lhs - rhs)
    }
}

enum RecordReference {
    static func make(prefix: String, id: UUID, date: Date) -> String {
        let year = Calendar(identifier: .gregorian).component(.year, from: date)
        let token = id.uuidString.replacingOccurrences(of: "-", with: "").prefix(12)
        return "\(prefix)-\(year)-\(token)"
    }
}

extension POSTransaction {
    var reference: String {
        RecordReference.make(prefix: "POS", id: id, date: transactionDate)
    }
}

extension Receivable {
    var reference: String {
        RecordReference.make(prefix: "ALCK", id: id, date: createdAt)
    }
}

extension Payment {
    var reference: String {
        RecordReference.make(prefix: "TAHSILAT", id: id, date: paymentDate)
    }
}

extension Invoice {
    var reference: String {
        RecordReference.make(prefix: "FAT", id: id, date: createdAt)
    }
}

extension BalanceTransaction {
    var reference: String {
        RecordReference.make(prefix: "HRK", id: id, date: date)
    }
}
