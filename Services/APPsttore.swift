import Foundation
import Combine

final class AppStore: ObservableObject {

    // MARK: - ANA VERİLER

    @Published var companies: [Company] = [] {
        didSet {
            save()
        }
    }

    @Published var posBanks: [POSBank] = [] {
        didSet {
            save()
        }
    }

    @Published var posTransactions: [POSTransaction] = [] {
        didSet {
            save()
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
            save()
        }
    }
    
            @Published var payments: [Payment] = [] {
                didSet {
                    save()
                
                }
            }                // MARK: - FİNANS ÖZETİ
                    
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
                    payments.reduce(0) {
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
        posTransactions.reduce(0) {
            $0 + $1.profitAmount
        }
    }

    var totalExpense: Double {
        paymentsTotal
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

        let companyID = company.id

        // Önce şirkete bağlı POS işlemlerini sil
        let bankIDs =
            posBanks
                .filter {
                    $0.companyID == companyID
                }
                .map {
                    $0.id
                }

        posTransactions.removeAll {
            bankIDs.contains(
                $0.posBankID
            )
        }

        // Şirketin POS bankalarını sil
        posBanks.removeAll {
            $0.companyID == companyID
        }

        // Şirketi sil
        companies.removeAll {
            $0.id == companyID
        }
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

        let bankID = bank.id

        // Bankaya ait POS işlemlerini de kaldır
        posTransactions.removeAll {
            $0.posBankID == bankID
        }

        posBanks.removeAll {
            $0.id == bankID
        }
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

        posTransactions.append(
            transaction
        )
    }


    func updatePOSTransaction(
        _ transaction: POSTransaction
    ) {

        if let index =
            posTransactions.firstIndex(
                where: {
                    $0.id == transaction.id
                }
            ) {

            posTransactions[index] =
                transaction
        }
    }


    func deletePOSTransaction(
        _ transaction: POSTransaction
    ) {

        posTransactions.removeAll {
            $0.id == transaction.id
        }
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
            .settled

        posTransactions[index].settlementDate =
            Date()
    }


    func markAsPending(
        _ transaction: POSTransaction
    ) {

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
                    posTransactions
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

            companies =
                decoded.companies

            posBanks =
                decoded.posBanks

            posTransactions =
                decoded.posTransactions

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
                    posTransactions
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

            companies =
                restored.companies

            posBanks =
                restored.posBanks

            posTransactions =
                restored.posTransactions

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
