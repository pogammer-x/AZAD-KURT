import Foundation

struct FinancialReportSummary {
    var grossPOSAmount: Double = 0
    var principalAmount: Double = 0
    var commissionAmount: Double = 0
    var netPOSAmount: Double = 0
    var netProfitAmount: Double = 0
    var grossProfitAmount: Double = 0
    var pendingAmount: Double = 0
    var settledAmount: Double = 0
    var transactionCount: Int = 0
    var cancelledTransactionCount: Int = 0
}

struct FinancialReportCalculator {
    static func transactions(
        from transactions: [POSTransaction],
        companyID: UUID? = nil,
        periodStart: Date,
        periodEnd: Date
    ) -> [POSTransaction] {
        transactions.filter { transaction in
            (companyID == nil || transaction.companyID == companyID) &&
            transaction.transactionDate >= periodStart &&
            transaction.transactionDate < periodEnd
        }
    }

    static func summary(
        transactions: [POSTransaction]
    ) -> FinancialReportSummary {
        var result = FinancialReportSummary()
        result.transactionCount = transactions.count
        result.cancelledTransactionCount = transactions.filter {
            $0.status == .cancelled
        }.count

        for transaction in transactions where transaction.status != .cancelled {
            result.grossPOSAmount += transaction.posAmount
            result.principalAmount += transaction.principalAmount
            result.commissionAmount += transaction.commissionAmount
            result.netPOSAmount += transaction.netBankAmount
            result.netProfitAmount += transaction.profitAmount
            result.grossProfitAmount += transaction.grossProfitAmount

            if transaction.status == .pending {
                result.pendingAmount += transaction.netBankAmount
            } else if transaction.status == .settled {
                result.settledAmount += transaction.netBankAmount
            }
        }

        return result
    }
}

struct ComprehensiveFinancialReport {
    var pos = FinancialReportSummary()
    var receivableAmount: Double = 0
    var paymentAmount: Double = 0
    var capitalInAmount: Double = 0
    var capitalOutAmount: Double = 0
    var manualIncomeAmount: Double = 0
    var manualExpenseAmount: Double = 0
}

extension FinancialReportCalculator {
    static func comprehensiveReport(
        posTransactions: [POSTransaction],
        receivables: [Receivable],
        payments: [Payment],
        balanceTransactions: [BalanceTransaction],
        manualTransactions: [Transaction],
        companyID: UUID? = nil,
        periodStart: Date,
        periodEnd: Date
    ) -> ComprehensiveFinancialReport {
        let filteredPOS = transactions(
            from: posTransactions,
            companyID: companyID,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
        let receivableTotal = receivables
            .filter {
                (companyID == nil || $0.companyID == companyID) &&
                $0.status != .cancelled &&
                $0.createdAt >= periodStart && $0.createdAt < periodEnd
            }
            .reduce(0) { $0 + $1.principalAmount }
        let paymentTotal = payments
            .filter {
                (companyID == nil || $0.companyID == companyID) &&
                !$0.isCancelled &&
                $0.paymentDate >= periodStart && $0.paymentDate < periodEnd
            }
            .reduce(0) { $0 + $1.amount }
        let capitalMovements = balanceTransactions.filter {
            (companyID == nil || $0.companyID == companyID) &&
            $0.date >= periodStart && $0.date < periodEnd
        }
        let filteredManualTransactions = manualTransactions.filter {
            (companyID == nil || $0.companyID == companyID) &&
            $0.transactionDate >= periodStart && $0.transactionDate < periodEnd
        }

        return ComprehensiveFinancialReport(
            pos: summary(transactions: filteredPOS),
            receivableAmount: receivableTotal,
            paymentAmount: paymentTotal,
            capitalInAmount: capitalMovements
                .filter { $0.type == .capitalContribution }
                .reduce(0) { $0 + $1.amount },
            capitalOutAmount: abs(
                capitalMovements
                    .filter { $0.type == .capitalWithdrawal }
                    .reduce(0) { $0 + $1.amount }
            ),
            manualIncomeAmount: filteredManualTransactions
                .filter { $0.type == .income }
                .reduce(0) { $0 + $1.amount },
            manualExpenseAmount: filteredManualTransactions
                .filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount }
        )
    }
}
