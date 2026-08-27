import Foundation

struct POSCalculationResult {
    var principalAmount: Double
    var posAmount: Double
    var commissionRate: Double
    
    var commissionAmount: Double
    var netBankAmount: Double
    var profitAmount: Double
}

struct POSCalculator {
    
    static func calculate(
        principalAmount: Double,
        posAmount: Double,
        commissionRate: Double
    ) -> POSCalculationResult {
        
        let rate = commissionRate / 100
        
        let commissionAmount = posAmount * rate
        
        let netBankAmount = posAmount - commissionAmount
        
        let profitAmount = netBankAmount - principalAmount
        
        return POSCalculationResult(
            principalAmount: principalAmount,
            posAmount: posAmount,
            commissionRate: commissionRate,
            commissionAmount: commissionAmount,
            netBankAmount: netBankAmount,
            profitAmount: profitAmount
        )
    }
}
