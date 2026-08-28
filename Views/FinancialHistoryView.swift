import SwiftUI

enum FinancialHistoryType: String, CaseIterable, Identifiable {
    case all, capital, posFunding, posTransaction, posSettlement
    case posReversal, manualAdjustment, receivable, payment
    case income, expense

    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: return "Tüm İşlemler"
        case .capital: return "Ana Para"
        case .posFunding: return "POS Ana Para Çıkışı"
        case .posTransaction: return "POS İşlemi"
        case .posSettlement: return "POS Netleşme"
        case .posReversal: return "POS İptal / Ters"
        case .manualAdjustment: return "Manuel Bakiye"
        case .receivable: return "Alacak"
        case .payment: return "Ödeme"
        case .income: return "Gelir"
        case .expense: return "Gider"
        }
    }
}

struct FinancialHistoryItem: Identifiable {
    var id: String
    var date: Date
    var type: FinancialHistoryType
    var companyID: UUID
    var posBankID: UUID?
    var amount: Double
    var description: String
    var relatedPOSTransactionID: UUID?
    var balanceDetail: String?
}

struct FinancialHistoryView: View {
    @EnvironmentObject var store: AppStore
    @State private var dateSelection: ReportDateSelection = .month
    @State private var customStart = Date()
    @State private var customEnd = Date()
    @State private var selectedCompanyID: UUID?
    @State private var selectedBankID: UUID?
    @State private var selectedType: FinancialHistoryType = .all

    var period: DateInterval {
        ReportingPeriodResolver.interval(
            selection: dateSelection,
            customStart: customStart,
            customEnd: customEnd
        )
    }

    var items: [FinancialHistoryItem] {
        let balanceItems = store.balanceTransactions.map { movement in
            FinancialHistoryItem(
                id: "balance-\(movement.id.uuidString)",
                date: movement.date,
                type: historyType(movement.type),
                companyID: movement.companyID,
                posBankID: movement.posBankID,
                amount: movement.amount,
                description: "\(movement.reference) · \(movement.description)",
                relatedPOSTransactionID: movement.relatedPOSTransactionID,
                balanceDetail: "\(currency(movement.oldBalance)) → \(currency(movement.newBalance))"
            )
        }
        let posItems = store.posTransactions.map { transaction in
            FinancialHistoryItem(
                id: "pos-\(transaction.id.uuidString)",
                date: transaction.transactionDate,
                type: .posTransaction,
                companyID: transaction.companyID,
                posBankID: transaction.posBankID,
                amount: transaction.posAmount,
                description: "\(transaction.customerName) · \(statusText(transaction.status))",
                relatedPOSTransactionID: transaction.id
            )
        }
        let receivableItems = store.receivables.map { receivable in
            FinancialHistoryItem(
                id: "receivable-\(receivable.id.uuidString)",
                date: receivable.createdAt,
                type: .receivable,
                companyID: receivable.companyID,
                amount: receivable.principalAmount,
                description: "\(receivable.debtorName) · \(receivable.reason)"
            )
        }
        let paymentItems = store.payments.filter { !$0.isCancelled }.map { payment in
            FinancialHistoryItem(
                id: "payment-\(payment.id.uuidString)",
                date: payment.paymentDate,
                type: .payment,
                companyID: payment.companyID,
                amount: payment.amount,
                description: "\(payment.payerName) · \(payment.note)"
            )
        }

        return (balanceItems + posItems + receivableItems + paymentItems)
            .filter { item in
                item.date >= period.start && item.date < period.end &&
                (selectedCompanyID == nil || item.companyID == selectedCompanyID) &&
                (selectedBankID == nil || item.posBankID == selectedBankID) &&
                (selectedType == .all || item.type == selectedType)
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("İşlem Geçmişi").font(.largeTitle).fontWeight(.bold)
            Text("Tüm finansal olayları ve bakiye etkilerini kronolojik olarak inceleyin.")
                .foregroundColor(.secondary)
            filters
            Divider()
            if items.isEmpty {
                Spacer()
                Text("Seçili filtrelerde finansal hareket bulunmuyor.")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(items) { historyRow($0) }
                    }
                }
            }
        }
        .padding(28)
    }

    var filters: some View {
        VStack(spacing: 10) {
            HStack {
                Picker("Tarih", selection: $dateSelection) {
                    ForEach(ReportDateSelection.allCases) { Text($0.title).tag($0) }
                }
                Picker("Şirket", selection: $selectedCompanyID) {
                    Text("Tüm Şirketler").tag(nil as UUID?)
                    ForEach(store.companies) { Text($0.name).tag($0.id as UUID?) }
                }
                Picker("POS Bankası", selection: $selectedBankID) {
                    Text("Tüm Bankalar").tag(nil as UUID?)
                    ForEach(store.posBanks) { Text($0.bankName).tag($0.id as UUID?) }
                }
                Picker("İşlem Türü", selection: $selectedType) {
                    ForEach(FinancialHistoryType.allCases) { Text($0.title).tag($0) }
                }
            }
            if dateSelection == .custom {
                HStack {
                    DatePicker("Başlangıç", selection: $customStart, displayedComponents: .date)
                    DatePicker("Bitiş", selection: $customEnd, displayedComponents: .date)
                }
            }
        }
    }

    func historyRow(_ item: FinancialHistoryItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.amount >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                .foregroundColor(item.amount >= 0 ? AppTheme.positive : AppTheme.negative)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.type.title).fontWeight(.semibold)
                Text(item.description).foregroundColor(.secondary)
                Text("\(companyName(item.companyID))\(bankSuffix(item.posBankID))")
                    .font(.caption).foregroundColor(.secondary)
                if let transactionID = item.relatedPOSTransactionID {
                    Text(
                        store.posTransactions.first { $0.id == transactionID }?.reference ??
                        "POS-\(transactionID.uuidString.prefix(8))"
                    )
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(signedCurrency(item.amount)).fontWeight(.bold)
                    .foregroundColor(item.amount >= 0 ? AppTheme.positive : AppTheme.negative)
                Text(dateText(item.date)).font(.caption).foregroundColor(.secondary)
                if let detail = item.balanceDetail {
                    Text(detail).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.card))
    }

    func historyType(_ type: BalanceTransactionType) -> FinancialHistoryType {
        switch type {
        case .capitalContribution, .capitalWithdrawal: return .capital
        case .posPrincipalDebit: return .posFunding
        case .posSettlementCredit: return .posSettlement
        case .posPrincipalRefund: return .posReversal
        case .manualAdjustment: return .manualAdjustment
        case .income: return .income
        case .expense: return .expense
        }
    }

    func companyName(_ id: UUID) -> String { store.company(for: id)?.name ?? "Bilinmeyen Şirket" }
    func bankSuffix(_ id: UUID?) -> String { id.map { " · \(store.bankName(for: $0))" } ?? "" }
    func statusText(_ status: POSTransactionStatus) -> String { status == .pending ? "Bekleyen" : status == .settled ? "Netleşen" : "İptal" }
    func signedCurrency(_ value: Double) -> String { (value > 0 ? "+" : "") + currency(value) }
    func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.currencyCode = "TRY"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0,00"
    }
    func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
}
