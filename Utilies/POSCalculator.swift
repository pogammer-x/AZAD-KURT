import Foundation

struct POSCalculationResult {
    var principalAmount: Double
    var posAmount: Double
    var commissionRate: Double
    
    var commissionAmount: Double
    var netBankAmount: Double
    var grossProfitAmount: Double
    var profitAmount: Double
}

struct POSCalculator {

    static func calculate(
        fundingSources: [POSFundingSource],
        posAmount: Double,
        commissionRate: Double
    ) -> POSCalculationResult {
        calculate(
            principalAmount: fundingSources.reduce(0) {
                $0 + $1.amount
            },
            posAmount: posAmount,
            commissionRate: commissionRate
        )
    }
    
    static func calculate(
        principalAmount: Double,
        posAmount: Double,
        commissionRate: Double
    ) -> POSCalculationResult {
        
        let rate = commissionRate / 100
        
        let commissionAmount = MoneyMath.rounded(posAmount * rate)
        
        let netBankAmount = MoneyMath.subtract(posAmount, commissionAmount)
        
        let grossProfitAmount = MoneyMath.subtract(posAmount, principalAmount)

        let profitAmount = MoneyMath.subtract(grossProfitAmount, commissionAmount)
        
        return POSCalculationResult(
            principalAmount: principalAmount,
            posAmount: posAmount,
            commissionRate: commissionRate,
            commissionAmount: commissionAmount,
            netBankAmount: netBankAmount,
            grossProfitAmount: grossProfitAmount,
            profitAmount: profitAmount
        )
    }
}
