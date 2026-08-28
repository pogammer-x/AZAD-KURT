import Foundation
import Combine

final class AppStore: ObservableObject {

    private var isBatchUpdating = false

    // MARK: - ANA VERİLER

    @Published var companies: [Company] = [] {
        didSet {
            saveIfNeeded()
        }
    }

    @Published var posBanks: [POSBank] = [] {
        didSet {
            saveIfNeeded()
        }
    }

    @Published var posTransactions: [POSTransaction] = [] {
        didSet {
            saveIfNeeded()
        }
    }
    func totalPOSAmount(for companyID: UUID) -> Double {
        posTransactions
            .filter { $0.companyID == companyID }
            .reduce(0) { $0 + $1.posAmount }
    }

    func totalBankDeduction(for companyID: UUID) -> Double {
        posTransactions
            .filter { $0.companyID == companyID }
            .reduce(0) { $0 + $1.commissionAmount }
    }

    func netBalance(for companyID: UUID) -> Double {
        posTransactions
            .filter { $0.companyID == companyID }
            .reduce(0) { $0 + $1.netBankAmount }
    }

    var totalAllCompaniesNetBalance: Double {
        posTransactions.reduce(0) { $0 + $1.netBankAmount }
    }
    func totalPOSAmount(for bankID: UUID, companyID: UUID) -> Double {
        posTransactions
            .filter {
                $0.companyID == companyID &&
                $0.posBankID == bankID
            }
            .reduce(0) { $0 + $1.posAmount }
    }

    func totalBankDeduction(for bankID: UUID, companyID: UUID) -> Double {
        posTransactions
            .filter {
                $0.companyID == companyID &&
                $0.posBankID == bankID
            }
            .reduce(0) { $0 + $1.commissionAmount }
    }

    func netBalance(for bankID: UUID, companyID: UUID) -> Double {
        posTransactions
            .filter {
                $0.companyID == companyID &&
                $0.posBankID == bankID
            }
            .reduce(0) { $0 + $1.netBankAmount }
    }
    @Published var receivables: [Receivable] = [] {
        didSet {
            saveIfNeeded()
        }
    }
    
            @Published var payments: [Payment] = [] {
                didSet {
                    saveIfNeeded()
                
                }
            }                // MARK: - FİNANS ÖZETİ

    @Published var balanceTransactions: [BalanceTransaction] = [] {
        didSet {
            saveIfNeeded()
        }
    }

    @Published var invoices: [Invoice] = [] {
        didSet {
            saveIfNeeded()
        }
    }

    @Published var transactions: [Transaction] = [] {
        didSet {
            saveIfNeeded()
        }
    }
                    
                    var settledPOSText: String {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencyCode = "TRY"
                    formatter.locale = Locale(identifier: "tr_TR")

                    return formatter.string(
                        from: NSNumber(value: settledPOSTotal)
                    ) ?? "₺0,00"
                }

                var paymentsTotal: Double {
                    payments.filter { !$0.isCancelled }.reduce(0) {
                        $0 + $1.amount
                    }
                }

                var paymentsText: String {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencyCode = "TRY"
                    formatter.locale = Locale(identifier: "tr_TR")

                    return formatter.string(
                        from: NSNumber(value: paymentsTotal)
                    ) ?? "₺0,00"
                }

                var receivablesTotal: Double {
                    receivables
                        .filter { $0.status == .active }
                        .reduce(0) {
                            $0 + max(0, $1.principalAmount - $1.totalPaid)
                        }
                }
    var totalIncome: Double {
        totalNetPOSProfit + manualIncomeTotal
    }

    var totalExpense: Double {
        manualExpenseTotal
    }

    var netProfit: Double {
        totalIncome - totalExpense
    }
                var receivablesText: String {
                    let formatter = NumberFormatter()
                    formatter.numberStyle = .currency
                    formatter.currencyCode = "TRY"
                    formatter.locale = Locale(identifier: "tr_TR")

                    return formatter.string(
                        from: NSNumber(value: receivablesTotal)
                    ) ?? "₺0,00"
                }

                var todayPOSProfit: Double {
                    posTransactions
                        .filter {
                            Calendar.current.isDateInToday($0.transactionDate)
                        }
                        .reduce(0) {
                            $0 + $1.profitAmount
                        }
                }
    var todayPOSProfitText: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")

        return formatter.string(
            from: NSNumber(value: todayPOSProfit)
        ) ?? "₺0,00"
    }
    var totalPOSCommission: Double {
                    posTransactions.reduce(0) {
                        $0 + $1.commissionAmount
                    }
                }

    var totalCapital: Double {
        balanceTransactions.reduce(0) { total, movement in
            switch movement.type {
            case .capitalContribution, .capitalWithdrawal:
                return total + movement.amount
            default:
                return total
            }
        }
    }

    var totalCashBalance: Double {
        companies.reduce(0) { $0 + $1.balance } +
        posBanks.reduce(0) { $0 + $1.balance }
    }

    var totalGrossPOSProfit: Double {
        posTransactions
            .filter { $0.status != .cancelled }
            .reduce(0) { $0 + $1.grossProfitAmount }
    }

    var totalNetPOSProfit: Double {
        posTransactions
            .filter { $0.status != .cancelled }
            .reduce(0) { $0 + $1.profitAmount }
    }

    var manualIncomeTotal: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var manualExpenseTotal: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }
                // MARK: - BAŞLAT 

    init() {
        load()
    }


    // =====================================================
    // MARK: - ŞİRKETLER
    // =====================================================

    func addCompany(_ company: Company) {

        companies.append(company)
    }


    func updateCompany(_ company: Company) {

        if let index = companies.firstIndex(
            where: {
                $0.id == company.id
            }
        ) {

            companies[index] = company
        }
    }


    func deleteCompany(_ company: Company) {
        _ = deleteCompanySafely(company)
    }

    @discardableResult
    func deleteCompanySafely(_ company: Company) -> FinancialOperationResult {
        let companyID = company.id
        let hasHistory = posBanks.contains { $0.companyID == companyID } ||
            posTransactions.contains { transaction in
                transaction.fundingSources.contains { $0.companyID == companyID }
            } || receivables.contains { $0.companyID == companyID } ||
            payments.contains { $0.companyID == companyID } ||
            balanceTransactions.contains { $0.companyID == companyID } ||
            invoices.contains { $0.companyID == companyID } ||
            transactions.contains { $0.companyID == companyID }
        guard !hasHistory else {
            return .failure("Finansal geçmişi bulunan şirket silinemez.")
        }
        companies.removeAll { $0.id == companyID }
        return .success
    }


    func company(
        for id: UUID
    ) -> Company? {

        return companies.first {
            $0.id == id
        }
    }


    // =====================================================
    // MARK: - POS BANKALARI
    // =====================================================

    func addPOSBank(_ bank: POSBank) {

        posBanks.append(bank)
    }


    func updatePOSBank(_ bank: POSBank) {

        if let index =
            posBanks.firstIndex(
                where: {
                    $0.id == bank.id
                }
            ) {

            posBanks[index] = bank
        }
    }


    func deletePOSBank(_ bank: POSBank) {
        _ = deletePOSBankSafely(bank)
    }

    @discardableResult
    func deletePOSBankSafely(_ bank: POSBank) -> FinancialOperationResult {
        let hasHistory = posTransactions.contains { $0.posBankID == bank.id } ||
            balanceTransactions.contains { $0.posBankID == bank.id }
        guard !hasHistory else {
            return .failure("Finansal geçmişi bulunan POS bankası silinemez.")
        }
        posBanks.removeAll { $0.id == bank.id }
        return .success
    }


    func banks(
        for companyID: UUID
    ) -> [POSBank] {

        return posBanks.filter {
            $0.companyID == companyID
        }
    }


    func bank(
        for bankID: UUID
    ) -> POSBank? {

        return posBanks.first {
            $0.id == bankID
        }
    }


    func bankName(
        for bankID: UUID
    ) -> String {

        return bank(
            for: bankID
        )?.bankName ?? "Bilinmeyen Banka"
    }


    // =====================================================
    // MARK: - POS İŞLEMLERİ
    // =====================================================

    func addPOSTransaction(
        _ transaction: POSTransaction
    ) {
        _ = createPOSTransaction(transaction)
    }


    func createPOSTransaction(
        _ transaction: POSTransaction
    ) -> FinancialOperationResult {
        if isInvoicePeriodLocked(
            companyID: transaction.companyID,
            date: transaction.transactionDate
        ) {
            return .failure(
                "İşlem tarihi kilitli bir fatura dönemine ait. Yeni POS kaydedilemez."
            )
        }
        if posTransactions.contains(where: { $0.id == transaction.id }) ||
            hasMovement(
                type: .posPrincipalDebit,
                posTransactionID: transaction.id
            ) {
            return .failure("Bu POS işlemi daha önce kaydedilmiş.")
        }

        guard transaction.status == .pending else {
            return .failure("Yeni POS işlemi bekleyen durumda olmalıdır.")
        }

        let groupedSources = Dictionary(
            grouping: transaction.fundingSources,
            by: { $0.companyID }
        ).mapValues { sources in
            sources.reduce(0) { $0 + $1.amount }
        }

        guard !groupedSources.isEmpty else {
            return .failure("En az bir ana para kaynağı seçilmelidir.")
        }

        let fundingTotal = groupedSources.values.reduce(0, +)
        guard abs(fundingTotal - transaction.principalAmount) < 0.01 else {
            return .failure("Ana para toplamı ile kaynak toplamı eşleşmiyor.")
        }

        for (companyID, amount) in groupedSources {
            guard amount > 0 else {
                return .failure("Kaynak tutarları sıfırdan büyük olmalıdır.")
            }
            guard let company = company(for: companyID) else {
                return .failure("Ana para kaynak şirketi bulunamadı.")
            }
            guard company.balance >= amount else {
                return .failure(
                    "\(company.name) şirketinin kullanılabilir bakiyesi yetersiz."
                )
            }
        }

        performBatchUpdate {
            for (companyID, amount) in groupedSources {
                guard let index = companies.firstIndex(
                    where: { $0.id == companyID }
                ) else {
                    continue
                }

                let oldBalance = companies[index].balance
                let newBalance = MoneyMath.subtract(oldBalance, amount)
                companies[index].balance = newBalance
                balanceTransactions.append(
                    BalanceTransaction(
                        companyID: companyID,
                        amount: -amount,
                        type: .posPrincipalDebit,
                        description: "POS işlemi ana para çıkışı",
                        relatedPOSTransactionID: transaction.id,
                        oldBalance: oldBalance,
                        newBalance: newBalance
                    )
                )
            }

            posTransactions.append(transaction)
        }

        return .success
    }


    func updatePOSTransaction(
        _ transaction: POSTransaction
    ) {
        _ = updatePOSTransactionSafely(transaction)
    }


    func updatePOSTransactionSafely(
        _ transaction: POSTransaction
    ) -> FinancialOperationResult {
        guard let index = posTransactions.firstIndex(
            where: { $0.id == transaction.id }
        ) else {
            return .failure("POS işlemi bulunamadı.")
        }

        let current = posTransactions[index]
        if isInvoicePeriodLocked(
            companyID: current.companyID,
            date: current.transactionDate
        ) || isInvoicePeriodLocked(
            companyID: transaction.companyID,
            date: transaction.transactionDate
        ) {
            return .failure(
                "POS işlemi kilitli bir fatura dönemini etkilediği için düzenlenemez."
            )
        }
        guard current.status == .pending else {
            return .failure(
                "Yalnızca bekleyen POS işlemleri düzenlenebilir."
            )
        }
        guard transaction.status == .pending else {
            return .failure("Düzenlenen POS işlemi bekleyen durumda kalmalıdır.")
        }

        let updatedFunding = Dictionary(
            grouping: transaction.fundingSources,
            by: { $0.companyID }
        ).mapValues { $0.reduce(0) { $0 + $1.amount } }
        guard !updatedFunding.isEmpty,
              updatedFunding.values.allSatisfy({ $0 > 0 }) else {
            return .failure("Ana para kaynakları geçersiz.")
        }
        guard abs(updatedFunding.values.reduce(0, +) - transaction.principalAmount) < 0.01 else {
            return .failure("Ana para toplamı ile kaynak toplamı eşleşmiyor.")
        }
        guard posBanks.contains(where: { $0.id == transaction.posBankID }) else {
            return .failure("POS bankası bulunamadı.")
        }

        let principalMovements = balanceTransactions.filter {
            $0.relatedPOSTransactionID == transaction.id &&
            ($0.type == .posPrincipalDebit || $0.type == .posPrincipalRefund)
        }
        let hasFinancialEffect = principalMovements.contains {
            $0.type == .posPrincipalDebit
        }

        // Eski JSON kayıtları hareket üretmeden yüklenir; bunları düzenlemek de
        // geçmiş bakiyeleri geriye dönük olarak çalıştırmaz.
        guard hasFinancialEffect else {
            posTransactions[index] = transaction
            return .success
        }

        let outstandingByCompany = Dictionary(
            grouping: principalMovements,
            by: { $0.companyID }
        ).mapValues { movements in
            max(0, -movements.reduce(0) { $0 + $1.amount })
        }

        for (companyID, newAmount) in updatedFunding {
            guard let company = company(for: companyID) else {
                return .failure("Ana para kaynak şirketi bulunamadı.")
            }
            let availableAfterReversal = MoneyMath.add(
                company.balance,
                outstandingByCompany[companyID] ?? 0
            )
            guard availableAfterReversal >= newAmount else {
                return .failure(
                    "\(company.name) şirketinin kullanılabilir bakiyesi yetersiz."
                )
            }
        }

        performBatchUpdate {
            for (companyID, amount) in outstandingByCompany where amount > 0 {
                guard let companyIndex = companies.firstIndex(
                    where: { $0.id == companyID }
                ) else { continue }
                let oldBalance = companies[companyIndex].balance
                let newBalance = MoneyMath.add(oldBalance, amount)
                companies[companyIndex].balance = newBalance
                balanceTransactions.append(
                    BalanceTransaction(
                        companyID: companyID,
                        amount: amount,
                        type: .posPrincipalRefund,
                        description: "POS düzenleme eski ana para etkisi geri alındı",
                        relatedPOSTransactionID: transaction.id,
                        oldBalance: oldBalance,
                        newBalance: newBalance
                    )
                )
            }

            for (companyID, amount) in updatedFunding {
                guard let companyIndex = companies.firstIndex(
                    where: { $0.id == companyID }
                ) else { continue }
                let oldBalance = companies[companyIndex].balance
                let newBalance = MoneyMath.subtract(oldBalance, amount)
                companies[companyIndex].balance = newBalance
                balanceTransactions.append(
                    BalanceTransaction(
                        companyID: companyID,
                        amount: -amount,
                        type: .posPrincipalDebit,
                        description: "POS düzenleme yeni ana para çıkışı",
                        relatedPOSTransactionID: transaction.id,
                        oldBalance: oldBalance,
                        newBalance: newBalance
                    )
                )
            }

            posTransactions[index] = transaction
        }
        return .success
    }


    func deletePOSTransaction(
        _ transaction: POSTransaction
    ) {
        _ = cancelPOSTransaction(transaction.id)
    }


    func transactions(
        for companyID: UUID
    ) -> [POSTransaction] {

        let bankIDs =
            banks(
                for: companyID
            )
            .map {
                $0.id
            }

        return posTransactions
            .filter {
                bankIDs.contains(
                    $0.posBankID
                )
            }
            .sorted {
                $0.transactionDate >
                $1.transactionDate
            }
    }


    func transactions(
        forBank bankID: UUID
    ) -> [POSTransaction] {

        return posTransactions
            .filter {
                $0.posBankID == bankID
            }
            .sorted {
                $0.transactionDate >
                $1.transactionDate
            }
    }


    // =====================================================
    // MARK: - POS DURUMU
    // =====================================================

    func markAsSettled(
        _ transaction: POSTransaction
    ) {
        _ = settlePOSTransaction(transaction.id)
    }


    func settlePOSTransaction(
        _ transactionID: UUID
    ) -> FinancialOperationResult {
        guard let transactionIndex = posTransactions.firstIndex(
            where: { $0.id == transactionID }
        ) else {
            return .failure("POS işlemi bulunamadı.")
        }

        let transaction = posTransactions[transactionIndex]
        if hasMovement(
            type: .posSettlementCredit,
            posTransactionID: transactionID
        ) {
            if transaction.status != .settled {
                performBatchUpdate {
                    posTransactions[transactionIndex].status = .settled
                    if posTransactions[transactionIndex].settlementDate == nil {
                        posTransactions[transactionIndex].settlementDate = Date()
                    }
                }
            }
            return .success
        }

        guard transaction.status == .pending else {
            if transaction.status == .settled {
                return .success
            }
            return .failure("İptal edilmiş POS işlemi netleştirilemez.")
        }

        guard let bankIndex = posBanks.firstIndex(
            where: { $0.id == transaction.posBankID }
        ) else {
            return .failure("POS bankası bulunamadı.")
        }

        performBatchUpdate {
            let oldBalance = posBanks[bankIndex].balance
            let newBalance = MoneyMath.add(oldBalance, transaction.netBankAmount)
            posBanks[bankIndex].balance = newBalance
            balanceTransactions.append(
                BalanceTransaction(
                    companyID: posBanks[bankIndex].companyID,
                    amount: transaction.netBankAmount,
                    type: .posSettlementCredit,
                    description: "POS net tutarı banka hesabına geçti",
                    relatedPOSTransactionID: transactionID,
                    posBankID: transaction.posBankID,
                    oldBalance: oldBalance,
                    newBalance: newBalance
                )
            )
            posTransactions[transactionIndex].status = .settled
            posTransactions[transactionIndex].settlementDate = Date()
        }

        return .success
    }


    func cancelPOSTransaction(
        _ transactionID: UUID
    ) -> FinancialOperationResult {
        guard let transactionIndex = posTransactions.firstIndex(
            where: { $0.id == transactionID }
        ) else {
            return .failure("POS işlemi bulunamadı.")
        }

        let transaction = posTransactions[transactionIndex]
        guard transaction.status != .settled else {
            return .failure(
                "Netleşmiş POS işlemi otomatik olarak iptal edilemez."
            )
        }
        if transaction.status == .cancelled {
            return .success
        }

        let principalMovements = balanceTransactions.filter {
            $0.relatedPOSTransactionID == transactionID &&
            ($0.type == .posPrincipalDebit || $0.type == .posPrincipalRefund)
        }

        performBatchUpdate {
            let outstandingByCompany = Dictionary(
                grouping: principalMovements,
                by: { $0.companyID }
            ).mapValues { movements in
                max(0, -movements.reduce(0) { $0 + $1.amount })
            }

                for (companyID, amount) in outstandingByCompany where amount > 0 {
                    guard let companyIndex = companies.firstIndex(
                        where: { $0.id == companyID }
                    ) else {
                        continue
                    }
                    let oldBalance = companies[companyIndex].balance
                    let newBalance = MoneyMath.add(oldBalance, amount)
                    companies[companyIndex].balance = newBalance
                    balanceTransactions.append(
                        BalanceTransaction(
                            companyID: companyID,
                            amount: amount,
                            type: .posPrincipalRefund,
                            description: "İptal edilen POS ana para iadesi",
                            relatedPOSTransactionID: transactionID,
                            oldBalance: oldBalance,
                            newBalance: newBalance
                        )
                    )
            }

            posTransactions[transactionIndex].status = .cancelled
        }

        return .success
    }


    func markAsPending(
        _ transaction: POSTransaction
    ) {

        if hasMovement(
            type: .posSettlementCredit,
            posTransactionID: transaction.id
        ) {
            return
        }

        guard let index =
            posTransactions.firstIndex(
                where: {
                    $0.id ==
                    transaction.id
                }
            )
        else {
            return
        }

        posTransactions[index].status =
            .pending

        posTransactions[index].settlementDate =
            nil
    }


    // =====================================================
    // MARK: - ANA PANEL HESAPLAMALARI
    // =====================================================

    var totalPOSVolume: Double {

        var total: Double = 0

        for transaction in posTransactions {

            if !isCancelled(transaction) {

                total +=
                    transaction.posAmount
            }
        }

        return total
    }


    var totalCommission: Double {

        var total: Double = 0

        for transaction in posTransactions {

            if !isCancelled(transaction) {

                total +=
                    transaction.commissionAmount
            }
        }

        return total
    }


    var totalProfit: Double {

        var total: Double = 0

        for transaction in posTransactions {

            if !isCancelled(transaction) {

                total +=
                    transaction.profitAmount
            }
        }

        return total
    }


    // Bankadan henüz hesaba geçmeyen NET POS
    var pendingPOSTotal: Double {

        var total: Double = 0

        for transaction in posTransactions {

            if isPending(transaction) {

                total +=
                    transaction.netBankAmount
            }
        }

        return total
    }


    // Hesaba geçmiş POS netleri
    var settledPOSTotal: Double {

        var total: Double = 0

        for transaction in posTransactions {

            if isSettled(transaction) {

                total +=
                    transaction.netBankAmount
            }
        }

        return total
    }


    // Şimdilik kasa = hesaba geçmiş POS netleri
    // Gelir/Gider modülü geldiğinde burayı genişleteceğiz.
    var cashTotal: Double {

        return settledPOSTotal
    }


    var todayPOSVolume: Double {

        var total: Double = 0

        for transaction in posTransactions {

            if
                !isCancelled(transaction) &&
                Calendar.current.isDateInToday(
                    transaction.transactionDate
                ) {

                total +=
                    transaction.posAmount
            }
        }

        return total
    }


    var todayProfit: Double {

        var total: Double = 0

        for transaction in posTransactions {

            if
                !isCancelled(transaction) &&
                Calendar.current.isDateInToday(
                    transaction.transactionDate
                ) {

                total +=
                    transaction.profitAmount
            }
        }

        return total
    }


    var thisMonthProfit: Double {

        let calendar =
            Calendar.current

        let now =
            Date()

        let nowYear =
            calendar.component(
                .year,
                from: now
            )

        let nowMonth =
            calendar.component(
                .month,
                from: now
            )

        var total: Double = 0

        for transaction in posTransactions {

            if isCancelled(transaction) {
                continue
            }

            let transactionYear =
                calendar.component(
                    .year,
                    from:
                        transaction.transactionDate
                )

            let transactionMonth =
                calendar.component(
                    .month,
                    from:
                        transaction.transactionDate
                )

            if
                transactionYear == nowYear &&
                transactionMonth == nowMonth {

                total +=
                    transaction.profitAmount
            }
        }

        return total
    }


    var thisWeekProfit: Double {

        let calendar =
            Calendar.current

        let now =
            Date()

        let nowWeek =
            calendar.component(
                .weekOfYear,
                from: now
            )

        let nowYear =
            calendar.component(
                .yearForWeekOfYear,
                from: now
            )

        var total: Double = 0

        for transaction in posTransactions {

            if isCancelled(transaction) {
                continue
            }

            let transactionWeek =
                calendar.component(
                    .weekOfYear,
                    from:
                        transaction.transactionDate
                )

            let transactionYear =
                calendar.component(
                    .yearForWeekOfYear,
                    from:
                        transaction.transactionDate
                )

            if
                transactionWeek == nowWeek &&
                transactionYear == nowYear {

                total +=
                    transaction.profitAmount
            }
        }

        return total
    }


    // =====================================================
    // MARK: - SON İŞLEMLER
    // =====================================================

    var recentPOSTransactions:
        [POSTransaction] {

        let sorted =
            posTransactions.sorted {

                $0.transactionDate >
                $1.transactionDate
            }

        return Array(
            sorted.prefix(10)
        )
    }


    // =====================================================
    // MARK: - DURUM KONTROLLERİ
    // =====================================================

    private func isPending(
        _ transaction: POSTransaction
    ) -> Bool {

        return transaction.status.rawValue ==
            POSTransactionStatus.pending.rawValue
    }


    private func isSettled(
        _ transaction: POSTransaction
    ) -> Bool {

        return transaction.status.rawValue ==
            POSTransactionStatus.settled.rawValue
    }


    private func isCancelled(
        _ transaction: POSTransaction
    ) -> Bool {

        return transaction.status.rawValue ==
            POSTransactionStatus.cancelled.rawValue
    }


    func adjustCompanyBalance(
        companyID: UUID,
        newBalance: Double,
        description: String,
        modifiedBy: String? = nil
    ) -> FinancialOperationResult {
        guard newBalance >= 0 else {
            return .failure("Şirket bakiyesi negatif olamaz.")
        }
        guard !description.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return .failure("Bakiye düzenlemesi için açıklama gereklidir.")
        }
        guard let index = companies.firstIndex(
            where: { $0.id == companyID }
        ) else {
            return .failure("Şirket bulunamadı.")
        }

        let oldBalance = companies[index].balance
        let difference = MoneyMath.subtract(newBalance, oldBalance)
        guard difference != 0 else {
            return .success
        }

        performBatchUpdate {
            companies[index].balance = newBalance
            balanceTransactions.append(
                BalanceTransaction(
                    companyID: companyID,
                    amount: difference,
                    type: .manualAdjustment,
                    description: description,
                    oldBalance: oldBalance,
                    newBalance: newBalance,
                    modifiedBy: modifiedBy,
                    modifiedAt: Date()
                )
            )
        }

        return .success
    }


    func adjustPOSBankBalance(
        bankID: UUID,
        newBalance: Double,
        description: String,
        modifiedBy: String? = nil
    ) -> FinancialOperationResult {
        guard newBalance >= 0 else {
            return .failure("POS banka bakiyesi negatif olamaz.")
        }
        guard !description.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty else {
            return .failure("Bakiye düzenlemesi için açıklama gereklidir.")
        }
        guard let index = posBanks.firstIndex(
            where: { $0.id == bankID }
        ) else {
            return .failure("POS bankası bulunamadı.")
        }

        let oldBalance = posBanks[index].balance
        let difference = MoneyMath.subtract(newBalance, oldBalance)
        guard difference != 0 else {
            return .success
        }

        performBatchUpdate {
            posBanks[index].balance = newBalance
            balanceTransactions.append(
                BalanceTransaction(
                    companyID: posBanks[index].companyID,
                    amount: difference,
                    type: .manualAdjustment,
                    description: description,
                    posBankID: bankID,
                    oldBalance: oldBalance,
                    newBalance: newBalance,
                    modifiedBy: modifiedBy,
                    modifiedAt: Date()
                )
            )
        }

        return .success
    }


    func addCapital(
        amount: Double,
        companyID: UUID,
        posBankID: UUID? = nil,
        movementID: UUID = UUID(),
        description: String
    ) -> FinancialOperationResult {
        recordCapitalMovement(
            amount: amount,
            companyID: companyID,
            posBankID: posBankID,
            movementID: movementID,
            type: .capitalContribution,
            description: description
        )
    }


    func withdrawCapital(
        amount: Double,
        companyID: UUID,
        posBankID: UUID? = nil,
        movementID: UUID = UUID(),
        description: String
    ) -> FinancialOperationResult {
        recordCapitalMovement(
            amount: amount,
            companyID: companyID,
            posBankID: posBankID,
            movementID: movementID,
            type: .capitalWithdrawal,
            description: description
        )
    }


    private func recordCapitalMovement(
        amount: Double,
        companyID: UUID,
        posBankID: UUID?,
        movementID: UUID,
        type: BalanceTransactionType,
        description: String
    ) -> FinancialOperationResult {
        if balanceTransactions.contains(where: { $0.id == movementID }) {
            return .success
        }
        guard amount > 0 else {
            return .failure("Ana para tutarı sıfırdan büyük olmalıdır.")
        }
        let cleanDescription = description.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard !cleanDescription.isEmpty else {
            return .failure("Ana para hareketi için açıklama gereklidir.")
        }
        guard type == .capitalContribution || type == .capitalWithdrawal else {
            return .failure("Geçersiz ana para hareket türü.")
        }

        let signedAmount = type == .capitalContribution ? amount : -amount

        if let posBankID {
            guard let bankIndex = posBanks.firstIndex(where: {
                $0.id == posBankID && $0.companyID == companyID
            }) else {
                return .failure("POS banka hesabı bulunamadı.")
            }
            let oldBalance = posBanks[bankIndex].balance
            let newBalance = MoneyMath.add(oldBalance, signedAmount)
            guard newBalance >= 0 else {
                return .failure("POS banka hesabında yeterli bakiye yok.")
            }

            performBatchUpdate {
                posBanks[bankIndex].balance = newBalance
                balanceTransactions.append(
                    BalanceTransaction(
                        id: movementID,
                        companyID: companyID,
                        amount: signedAmount,
                        type: type,
                        description: cleanDescription,
                        posBankID: posBankID,
                        oldBalance: oldBalance,
                        newBalance: newBalance
                    )
                )
            }
            return .success
        }

        guard let companyIndex = companies.firstIndex(where: {
            $0.id == companyID
        }) else {
            return .failure("Şirket bulunamadı.")
        }
        let oldBalance = companies[companyIndex].balance
        let newBalance = MoneyMath.add(oldBalance, signedAmount)
        guard newBalance >= 0 else {
            return .failure("Şirket hesabında yeterli bakiye yok.")
        }

        performBatchUpdate {
            companies[companyIndex].balance = newBalance
            balanceTransactions.append(
                BalanceTransaction(
                    id: movementID,
                    companyID: companyID,
                    amount: signedAmount,
                    type: type,
                    description: cleanDescription,
                    oldBalance: oldBalance,
                    newBalance: newBalance
                )
            )
        }
        return .success
    }


    func recordManualTransaction(
        id: UUID = UUID(),
        companyID: UUID,
        type: TransactionType,
        title: String,
        amount: Double,
        date: Date = Date(),
        note: String,
        createdBy: String = "Kullanıcı"
    ) -> FinancialOperationResult {
        if transactions.contains(where: { $0.id == id }) {
            return .success
        }
        guard type == .income || type == .expense else {
            return .failure("Yalnızca gerçek gelir veya gider kaydedilebilir.")
        }
        guard amount > 0 else {
            return .failure("İşlem tutarı sıfırdan büyük olmalıdır.")
        }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            return .failure("İşlem başlığı gereklidir.")
        }
        guard let companyIndex = companies.firstIndex(
            where: { $0.id == companyID }
        ) else {
            return .failure("Şirket bulunamadı.")
        }

        let signedAmount = type == .income ? amount : -amount
        let oldBalance = companies[companyIndex].balance
        let newBalance = MoneyMath.add(oldBalance, signedAmount)
        guard newBalance >= 0 else {
            return .failure("Şirket hesabında yeterli bakiye yok.")
        }

        performBatchUpdate {
            companies[companyIndex].balance = newBalance
            transactions.append(
                Transaction(
                    id: id,
                    companyID: companyID,
                    type: type,
                    title: cleanTitle,
                    note: note,
                    amount: amount,
                    transactionDate: date,
                    posTransactionID: nil,
                    receivableID: nil,
                    paymentID: nil,
                    createdBy: createdBy
                )
            )
            balanceTransactions.append(
                BalanceTransaction(
                    id: id,
                    companyID: companyID,
                    amount: signedAmount,
                    type: type == .income ? .income : .expense,
                    date: date,
                    description: cleanTitle + (note.isEmpty ? "" : " · \(note)"),
                    oldBalance: oldBalance,
                    newBalance: newBalance,
                    createdBy: createdBy
                )
            )
        }
        return .success
    }

    func recordReceivablePayment(
        _ payment: Payment
    ) -> FinancialOperationResult {
        if payments.contains(where: { $0.id == payment.id }) {
            return .success
        }
        guard payment.amount > 0 else {
            return .failure("Tahsilat tutarı sıfırdan büyük olmalıdır.")
        }
        guard let index = receivables.firstIndex(where: {
            $0.id == payment.receivableID && $0.companyID == payment.companyID
        }) else {
            return .failure("İlgili alacak bulunamadı.")
        }
        guard receivables[index].status != .cancelled else {
            return .failure("İptal edilmiş alacağa tahsilat eklenemez.")
        }
        let remaining = InterestCalculator.receivableCurrentAmount(
            receivables[index],
            payments: payments
        )
        guard payment.amount <= remaining else {
            return .failure("Tahsilat kalan alacak tutarını aşamaz.")
        }

        performBatchUpdate {
            payments.append(payment)
            receivables[index].totalPaid = MoneyMath.add(
                receivables[index].totalPaid,
                payment.amount
            )
            receivables[index].updatedAt = Date()
            if InterestCalculator.receivableCurrentAmount(
                receivables[index],
                payments: payments
            ) <= 0 {
                receivables[index].status = .paid
            }
        }
        return .success
    }

    func cancelReceivablePayment(
        paymentID: UUID,
        cancelledBy: String? = nil
    ) -> FinancialOperationResult {
        guard let paymentIndex = payments.firstIndex(where: {
            $0.id == paymentID
        }) else {
            return .failure("Tahsilat bulunamadı.")
        }
        if payments[paymentIndex].isCancelled {
            return .success
        }
        guard let receivableIndex = receivables.firstIndex(where: {
            $0.id == payments[paymentIndex].receivableID
        }) else {
            return .failure("Tahsilatın bağlı olduğu alacak bulunamadı.")
        }

        performBatchUpdate {
            payments[paymentIndex].isCancelled = true
            payments[paymentIndex].cancelledBy = cancelledBy
            payments[paymentIndex].cancelledAt = Date()
            receivables[receivableIndex].totalPaid = MoneyMath.rounded(max(
                receivables[receivableIndex].totalPaid - payments[paymentIndex].amount,
                0
            ))
            receivables[receivableIndex].updatedAt = Date()
            if receivables[receivableIndex].status == .paid {
                receivables[receivableIndex].status = .active
            }
        }
        return .success
    }

    func searchPOSTransactions(
        query: String = "",
        companyID: UUID? = nil,
        posBankID: UUID? = nil,
        status: POSTransactionStatus? = nil,
        periodStart: Date? = nil,
        periodEnd: Date? = nil
    ) -> [POSTransaction] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return posTransactions.filter { transaction in
            let bank = bank(for: transaction.posBankID)
            let matchesCompany = companyID == nil || bank?.companyID == companyID
            let matchesBank = posBankID == nil || transaction.posBankID == posBankID
            let matchesStatus = status == nil || transaction.status == status
            let matchesStart = periodStart == nil || transaction.transactionDate >= periodStart!
            let matchesEnd = periodEnd == nil || transaction.transactionDate <= periodEnd!
            let matchesTerm = term.isEmpty ||
                transaction.customerName.lowercased().contains(term) ||
                transaction.reference.lowercased().contains(term) ||
                (bank?.bankName.lowercased().contains(term) ?? false)
            return matchesCompany && matchesBank && matchesStatus &&
                matchesStart && matchesEnd && matchesTerm
        }
    }


    func reportTransactions(
        companyID: UUID? = nil,
        periodStart: Date,
        periodEnd: Date
    ) -> [POSTransaction] {
        FinancialReportCalculator.transactions(
            from: posTransactions,
            companyID: companyID,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
    }


    func reportSummary(
        companyID: UUID? = nil,
        periodStart: Date,
        periodEnd: Date
    ) -> FinancialReportSummary {
        FinancialReportCalculator.summary(
            transactions: reportTransactions(
                companyID: companyID,
                periodStart: periodStart,
                periodEnd: periodEnd
            )
        )
    }


    func comprehensiveReport(
        companyID: UUID? = nil,
        periodStart: Date,
        periodEnd: Date
    ) -> ComprehensiveFinancialReport {
        FinancialReportCalculator.comprehensiveReport(
            posTransactions: posTransactions,
            receivables: receivables,
            payments: payments,
            balanceTransactions: balanceTransactions,
            manualTransactions: transactions,
            companyID: companyID,
            periodStart: periodStart,
            periodEnd: periodEnd
        )
    }


    func saveInvoiceSnapshot(
        companyID: UUID,
        periodStart: Date,
        periodEnd: Date
    ) -> FinancialOperationResult {
        guard periodStart < periodEnd else {
            return .failure("Fatura dönemi geçersiz.")
        }

        let summary = reportSummary(
            companyID: companyID,
            periodStart: periodStart,
            periodEnd: periodEnd
        )

        if let index = invoices.firstIndex(where: {
            $0.companyID == companyID &&
            $0.periodStart == periodStart &&
            $0.periodEnd == periodEnd
        }) {
            guard !invoices[index].isLocked else {
                return .failure("Kilitli fatura dönemi yeniden hesaplanamaz.")
            }
            Self.apply(summary: summary, to: &invoices[index])
            invoices[index].updatedAt = Date()
        } else {
            invoices.append(
                Invoice(
                    companyID: companyID,
                    periodStart: periodStart,
                    periodEnd: periodEnd,
                    grossPOSAmount: summary.grossPOSAmount,
                    principalAmount: summary.principalAmount,
                    commissionAmount: summary.commissionAmount,
                    netPOSAmount: summary.netPOSAmount,
                    settledAmount: summary.settledAmount,
                    pendingAmount: summary.pendingAmount,
                    netProfitAmount: summary.netProfitAmount,
                    transactionCount: summary.transactionCount,
                    cancelledTransactionCount: summary.cancelledTransactionCount
                )
            )
        }
        return .success
    }


    func lockInvoice(_ invoiceID: UUID) -> FinancialOperationResult {
        guard let index = invoices.firstIndex(where: { $0.id == invoiceID }) else {
            return .failure("Fatura kaydı bulunamadı.")
        }
        if invoices[index].isLocked {
            return .success
        }

        let summary = reportSummary(
            companyID: invoices[index].companyID,
            periodStart: invoices[index].periodStart,
            periodEnd: invoices[index].periodEnd
        )
        Self.apply(summary: summary, to: &invoices[index])
        invoices[index].isLocked = true
        invoices[index].lockedAt = Date()
        invoices[index].updatedAt = Date()
        return .success
    }


    func markInvoiceAsInvoiced(
        _ invoiceID: UUID,
        invoiceDate: Date?,
        invoiceNumber: String?,
        note: String
    ) -> FinancialOperationResult {
        guard let index = invoices.firstIndex(where: { $0.id == invoiceID }) else {
            return .failure("Fatura kaydı bulunamadı.")
        }
        invoices[index].status = .invoiced
        invoices[index].invoiceDate = invoiceDate ?? Date()
        invoices[index].invoiceNumber = invoiceNumber?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        invoices[index].note = note
        invoices[index].updatedAt = Date()
        return .success
    }


    func isInvoicePeriodLocked(
        companyID: UUID,
        date: Date
    ) -> Bool {
        invoices.contains { invoice in
            invoice.companyID == companyID &&
            invoice.isLocked &&
            invoice.status != .cancelled &&
            date >= invoice.periodStart &&
            date < invoice.periodEnd
        }
    }


    private static func apply(
        summary: FinancialReportSummary,
        to invoice: inout Invoice
    ) {
        invoice.grossPOSAmount = summary.grossPOSAmount
        invoice.principalAmount = summary.principalAmount
        invoice.commissionAmount = summary.commissionAmount
        invoice.netPOSAmount = summary.netPOSAmount
        invoice.settledAmount = summary.settledAmount
        invoice.pendingAmount = summary.pendingAmount
        invoice.netProfitAmount = summary.netProfitAmount
        invoice.transactionCount = summary.transactionCount
        invoice.cancelledTransactionCount = summary.cancelledTransactionCount
    }


    private func hasMovement(
        type: BalanceTransactionType,
        posTransactionID: UUID
    ) -> Bool {
        balanceTransactions.contains {
            $0.type == type &&
            $0.relatedPOSTransactionID == posTransactionID
        }
    }


    private func performBatchUpdate(
        _ updates: () -> Void
    ) {
        isBatchUpdating = true
        updates()
        isBatchUpdating = false
        save()
    }


    private func saveIfNeeded() {
        if !isBatchUpdating {
            save()
        }
    }


    // =====================================================
    // MARK: - KALICI KAYIT MODELİ
    // =====================================================

    private struct StoredData:
        Codable {

        var companies:
            [Company]

        var posBanks:
            [POSBank]

        var posTransactions:
            [POSTransaction]

        var receivables:
            [Receivable]

        var payments:
            [Payment]

        var balanceTransactions:
            [BalanceTransaction]

        var invoices:
            [Invoice]

        var transactions:
            [Transaction]

        init(
            companies: [Company],
            posBanks: [POSBank],
            posTransactions: [POSTransaction],
            receivables: [Receivable],
            payments: [Payment],
            balanceTransactions: [BalanceTransaction],
            invoices: [Invoice],
            transactions: [Transaction]
        ) {
            self.companies = companies
            self.posBanks = posBanks
            self.posTransactions = posTransactions
            self.receivables = receivables
            self.payments = payments
            self.balanceTransactions = balanceTransactions
            self.invoices = invoices
            self.transactions = transactions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(
                keyedBy: CodingKeys.self
            )

            companies = try container.decode(
                [Company].self,
                forKey: .companies
            )
            posBanks = try container.decode(
                [POSBank].self,
                forKey: .posBanks
            )
            posTransactions = try container.decode(
                [POSTransaction].self,
                forKey: .posTransactions
            )
            receivables = try container.decodeIfPresent(
                [Receivable].self,
                forKey: .receivables
            ) ?? []
            payments = try container.decodeIfPresent(
                [Payment].self,
                forKey: .payments
            ) ?? []
            balanceTransactions = try container.decodeIfPresent(
                [BalanceTransaction].self,
                forKey: .balanceTransactions
            ) ?? []
            invoices = try container.decodeIfPresent(
                [Invoice].self,
                forKey: .invoices
            ) ?? []
            transactions = try container.decodeIfPresent(
                [Transaction].self,
                forKey: .transactions
            ) ?? []
        }
    }


    // =====================================================
    // MARK: - DOSYA KONUMU
    // =====================================================

    private var dataURL: URL? {

        let fileManager =
            FileManager.default

        guard let baseURL =
            fileManager.urls(
                for:
                    .applicationSupportDirectory,
                in:
                    .userDomainMask
            )
            .first
        else {

            return nil
        }

        let folderURL =
            baseURL.appendingPathComponent(
                "AzadogluManager",
                isDirectory: true
            )

        do {

            try fileManager.createDirectory(
                at: folderURL,
                withIntermediateDirectories: true,
                attributes: nil
            )

        } catch {

            print(
                "Veri klasörü oluşturulamadı:",
                error
            )

            return nil
        }

        return folderURL
            .appendingPathComponent(
                "AzadogluManagerData.json"
            )
    }


    // =====================================================
    // MARK: - KAYDET
    // =====================================================

    func save() {

        guard let url =
            dataURL
        else {

            return
        }

        let data =
            StoredData(
                companies:
                    companies,

                posBanks:
                    posBanks,

                posTransactions:
                    posTransactions,

                receivables:
                    receivables,

                payments:
                    payments,

                balanceTransactions:
                    balanceTransactions,

                invoices:
                    invoices,

                transactions:
                    transactions
            )

        let encoder =
            JSONEncoder()

        encoder.outputFormatting =
            .prettyPrinted

        do {

            let encoded =
                try encoder.encode(
                    data
                )

            try encoded.write(
                to: url,
                options: .atomic
            )

        } catch {

            print(
                "Azadoğlu Manager kayıt hatası:",
                error
            )
        }
    }


    // =====================================================
    // MARK: - YÜKLE
    // =====================================================

    func load() {

        guard let url =
            dataURL
        else {

            return
        }

        guard
            FileManager.default
                .fileExists(
                    atPath: url.path
                )
        else {

            return
        }

        do {

            let data =
                try Data(
                    contentsOf: url
                )

            let decoder =
                JSONDecoder()

            let decoded =
                try decoder.decode(
                    StoredData.self,
                    from: data
                )

            isBatchUpdating = true

            companies =
                decoded.companies

            posBanks =
                decoded.posBanks

            posTransactions =
                decoded.posTransactions

            receivables =
                decoded.receivables

            payments =
                decoded.payments

            balanceTransactions =
                decoded.balanceTransactions

            invoices =
                decoded.invoices

            transactions =
                decoded.transactions

            isBatchUpdating = false

        } catch {

            print(
                "Azadoğlu Manager veri yükleme hatası:",
                error
            )
        }
    }


    // =====================================================
    // MARK: - YEDEKLEME
    // =====================================================

    func backupData() -> Data? {

        let stored =
            StoredData(
                companies:
                    companies,

                posBanks:
                    posBanks,

                posTransactions:
                    posTransactions,

                receivables:
                    receivables,

                payments:
                    payments,

                balanceTransactions:
                    balanceTransactions,

                invoices:
                    invoices,

                transactions:
                    transactions
            )

        let encoder =
            JSONEncoder()

        encoder.outputFormatting =
            .prettyPrinted

        return try? encoder.encode(
            stored
        )
    }


    // =====================================================
    // MARK: - YEDEKTEN GERİ YÜKLE
    // =====================================================

    func restoreBackup(
        from data: Data
    ) -> Bool {

        let decoder =
            JSONDecoder()

        do {

            let restored =
                try decoder.decode(
                    StoredData.self,
                    from: data
                )

            isBatchUpdating = true

            companies =
                restored.companies

            posBanks =
                restored.posBanks

            posTransactions =
                restored.posTransactions

            receivables =
                restored.receivables

            payments =
                restored.payments

            balanceTransactions =
                restored.balanceTransactions

            invoices =
                restored.invoices

            transactions =
                restored.transactions

            isBatchUpdating = false
            save()

            return true

        } catch {

            print(
                "Yedek geri yüklenemedi:",
                error
            )

            return false
        }
    }
}
