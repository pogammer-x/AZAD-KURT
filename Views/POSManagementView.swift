import SwiftUI

struct POSManagementView: View {
    @EnvironmentObject var store: AppStore

    @State private var statusFilter: POSStatusFilter = .pending
    @State private var dateFilter: POSDateFilter = .all
    @State private var selectedCompanyID: UUID?
    @State private var selectedBankID: UUID?
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()

    @State private var newTransactionCompany: Company?
    @State private var editingTransaction: POSTransaction?
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            headerSection
            summarySection
            filterSection
            Divider()

            if filteredTransactions.isEmpty {
                emptySection
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTransactions) { transaction in
                            transactionCard(transaction)
                        }
                    }
                }
            }
        }
        .padding(28)
        .sheet(item: $newTransactionCompany) { company in
            POSTransactionView(
                company: company,
                posBanks: store.banks(for: company.id),
                fundingCompanies: store.companies,
                onSave: { transaction in
                    handleCreate(transaction)
                }
            )
        }
        .sheet(item: $editingTransaction) { transaction in
            if let company = store.company(for: transaction.companyID) {
                POSTransactionView(
                    company: company,
                    posBanks: store.banks(for: company.id),
                    fundingCompanies: store.companies,
                    editingTransaction: transaction,
                    onSave: { updated in
                        handleUpdate(updated)
                    }
                )
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("POS İşlemi Hatası"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("POS İşlemleri")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Bekleyen, netleşen ve iptal edilen POS hareketlerini yönetin.")
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 10) {
                Picker("Kaynak Şirket", selection: $selectedCompanyID) {
                    Text("Şirket Seçin").tag(nil as UUID?)
                    ForEach(store.companies) { company in
                        Text(company.name).tag(company.id as UUID?)
                    }
                }
                .frame(width: 190)

                Button(action: {
                    if let companyID = selectedCompanyID,
                       let company = store.company(for: companyID) {
                        newTransactionCompany = company
                    }
                }) {
                    Label("Yeni POS İşlemi", systemImage: "plus")
                        .accentButton()
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(selectedCompanyID == nil)
            }
        }
        .background(AppTheme.background.edgesIgnoringSafeArea(.all))
        .corporateScreen()
    }

    var summarySection: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 180), spacing: 12)],
            spacing: 12
        ) {
            summaryCard("Bekleyen Brüt", pendingGross, "clock.fill")
            summaryCard("Bekleyen POS Neti", pendingNet, "hourglass")
            summaryCard("Netleşen POS", settledNet, "checkmark.circle.fill")
            summaryCard("Toplam Komisyon", activeCommission, "percent")
            summaryCard("Gerçek Net Kâr", activeProfit, "chart.line.uptrend.xyaxis")
        }
    }

    func summaryCard(_ title: String, _ amount: Double, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Image(systemName: icon)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(currency(amount))
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardElevated))
    }

    var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Durum", selection: $statusFilter) {
                ForEach(POSStatusFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Picker("Tarih", selection: $dateFilter) {
                    ForEach(POSDateFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }

                Picker("Şirket", selection: $selectedCompanyID) {
                    Text("Tüm Şirketler").tag(nil as UUID?)
                    ForEach(store.companies) { company in
                        Text(company.name).tag(company.id as UUID?)
                    }
                }

                Picker("POS Bankası", selection: $selectedBankID) {
                    Text("Tüm Bankalar").tag(nil as UUID?)
                    ForEach(availableBanks) { bank in
                        Text(bank.bankName).tag(bank.id as UUID?)
                    }
                }
            }

            if dateFilter == .custom {
                HStack {
                    DatePicker("Başlangıç", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("Bitiş", selection: $customEndDate, displayedComponents: .date)
                }
            }
        }
    }

    var emptySection: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "creditcard")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            Text("Seçili filtrelerde POS işlemi bulunmuyor")
                .font(.headline)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func transactionCard(_ transaction: POSTransaction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(transaction.reference) · \(transaction.customerName)")
                        .font(.headline)
                    Text("\(companyName(transaction.companyID)) · \(store.bankName(for: transaction.posBankID))")
                        .foregroundColor(.secondary)
                    Text(dateText(transaction.transactionDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                statusBadge(transaction.status)
            }

            Divider()

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 130), spacing: 12)],
                spacing: 8
            ) {
                valueCell("Brüt", transaction.posAmount)
                valueCell("Ana Para", transaction.principalAmount)
                valueCell("Komisyon", transaction.commissionAmount)
                valueCell("POS Neti", transaction.netBankAmount)
                valueCell("Net Kâr", transaction.profitAmount)
            }

            HStack {
                Spacer()
                if transaction.status == .pending {
                    Button("Düzenle") { editingTransaction = transaction }
                    Button("Netleştir") { settle(transaction) }
                        .buttonStyle(DefaultButtonStyle())
                    Button("İptal Et") { cancel(transaction) }
                        .foregroundColor(.red)
                } else if transaction.status == .settled {
                    Button("İptal Et") { cancel(transaction) }
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
    }

    func valueCell(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(currency(value)).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func statusBadge(_ status: POSTransactionStatus) -> some View {
        Text(statusTitle(status))
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(statusColor(status).opacity(0.16)))
            .foregroundColor(statusColor(status))
    }

    var availableBanks: [POSBank] {
        guard let companyID = selectedCompanyID else { return store.posBanks }
        return store.banks(for: companyID)
    }

    var baseFilteredTransactions: [POSTransaction] {
        store.posTransactions.filter { transaction in
            (selectedCompanyID == nil || transaction.companyID == selectedCompanyID) &&
            (selectedBankID == nil || transaction.posBankID == selectedBankID) &&
            matchesDate(transaction.transactionDate)
        }
    }

    var filteredTransactions: [POSTransaction] {
        baseFilteredTransactions
            .filter { statusFilter.matches($0.status) }
            .sorted { $0.transactionDate > $1.transactionDate }
    }

    var activeSummaryTransactions: [POSTransaction] {
        baseFilteredTransactions.filter { $0.status != .cancelled }
    }

    var pendingGross: Double { activeSummaryTransactions.filter { $0.status == .pending }.reduce(0) { $0 + $1.posAmount } }
    var pendingNet: Double { activeSummaryTransactions.filter { $0.status == .pending }.reduce(0) { $0 + $1.netBankAmount } }
    var settledNet: Double { activeSummaryTransactions.filter { $0.status == .settled }.reduce(0) { $0 + $1.netBankAmount } }
    var activeCommission: Double { activeSummaryTransactions.reduce(0) { $0 + $1.commissionAmount } }
    var activeProfit: Double { activeSummaryTransactions.reduce(0) { $0 + $1.profitAmount } }

    func matchesDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        switch dateFilter {
        case .all: return true
        case .today: return calendar.isDateInToday(date)
        case .week: return calendar.dateInterval(of: .weekOfYear, for: now)?.contains(date) ?? false
        case .month: return calendar.dateInterval(of: .month, for: now)?.contains(date) ?? false
        case .year: return calendar.dateInterval(of: .year, for: now)?.contains(date) ?? false
        case .custom:
            let start = calendar.startOfDay(for: min(customStartDate, customEndDate))
            let endDay = calendar.startOfDay(for: max(customStartDate, customEndDate))
            let end = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
            return date >= start && date < end
        }
    }

    func handleCreate(_ transaction: POSTransaction) -> FinancialOperationResult {
        let result = store.createPOSTransaction(transaction)
        if case .success = result {
            newTransactionCompany = nil
        }
        return result
    }

    func handleUpdate(_ transaction: POSTransaction) -> FinancialOperationResult {
        let result = store.updatePOSTransactionSafely(transaction)
        if case .success = result {
            editingTransaction = nil
        }
        return result
    }

    func settle(_ transaction: POSTransaction) {
        handle(store.settlePOSTransaction(transaction.id)) {}
    }

    func cancel(_ transaction: POSTransaction) {
        handle(store.cancelPOSTransaction(transaction.id)) {}
    }

    func handle(_ result: FinancialOperationResult, onSuccess: () -> Void) {
        switch result {
        case .success: onSuccess()
        case .failure(let message):
            errorMessage = message
            showError = true
        }
    }

    func companyName(_ id: UUID) -> String { store.company(for: id)?.name ?? "Bilinmeyen Şirket" }

    func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: value)) ?? "₺0,00"
    }

    func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }

    func statusTitle(_ status: POSTransactionStatus) -> String {
        switch status { case .pending: return "Bekleyen"; case .settled: return "Netleşen"; case .cancelled: return "İptal" }
    }

    func statusColor(_ status: POSTransactionStatus) -> Color {
        switch status {
        case .pending: return AppTheme.warning
        case .settled: return AppTheme.positive
        case .cancelled: return AppTheme.negative
        }
    }
}

enum POSStatusFilter: String, CaseIterable, Identifiable {
    case all, pending, settled, cancelled
    var id: String { rawValue }
    var title: String { switch self { case .all: return "Tümü"; case .pending: return "Bekleyen"; case .settled: return "Netleşen"; case .cancelled: return "İptal" } }
    func matches(_ status: POSTransactionStatus) -> Bool {
        switch self { case .all: return true; case .pending: return status == .pending; case .settled: return status == .settled; case .cancelled: return status == .cancelled }
    }
}

enum POSDateFilter: String, CaseIterable, Identifiable {
    case all, today, week, month, year, custom
    var id: String { rawValue }
    var title: String { switch self { case .all: return "Tüm Tarihler"; case .today: return "Bugün"; case .week: return "Bu Hafta"; case .month: return "Bu Ay"; case .year: return "Bu Yıl"; case .custom: return "Özel Aralık" } }
}
