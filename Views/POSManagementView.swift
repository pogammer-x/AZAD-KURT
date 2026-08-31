import SwiftUI

struct POSManagementView: View {
    @EnvironmentObject var store: AppStore

    @State private var statusFilter: POSStatusFilter = .pending
    @State private var dateFilter: POSDateFilter = .all
    @State private var selectedPOSCompanyID: UUID?
    @State private var selectedBankID: UUID?
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    @State private var newTransactionCompany: Company?
    @State private var editingTransaction: POSTransaction?
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    summarySection
                    filterSection

                    if filteredTransactions.isEmpty {
                        emptySection
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTransactions) { transaction in
                                transactionCard(transaction)
                            }
                        }
                    }
                }
                .padding(28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
        .corporateScreen()
        .sheet(item: $newTransactionCompany) { company in
            POSTransactionView(
                company: company,
                posBanks: store.banks(for: company.id),
                fundingCompanies: store.companies,
                onSave: handleCreate
            )
        }
        .sheet(item: $editingTransaction) { transaction in
            if let company = store.company(for: transaction.companyID) {
                POSTransactionView(
                    company: company,
                    posBanks: store.banks(for: company.id),
                    fundingCompanies: store.companies,
                    editingTransaction: transaction,
                    onSave: handleUpdate
                )
            }
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("POS İşlemi Hatası"), message: Text(errorMessage), dismissButton: .default(Text("Tamam")))
        }
    }

    private var headerSection: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text("POS İşlemleri")
                    .font(.system(size: 29, weight: .bold))
                Text("POS hareketlerini takip edin ve yönetin")
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Menu {
                ForEach(store.companies) { company in
                    Button(company.name) { newTransactionCompany = company }
                }
            } label: {
                Label("Yeni POS İşlemi", systemImage: "plus")
                    .accentButton()
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .disabled(store.companies.isEmpty)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 22)
        .background(AppTheme.panel)
        .overlay(Rectangle().fill(AppTheme.accent).frame(height: 2), alignment: .bottom)
    }

    private var summarySection: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 165), spacing: 12)], spacing: 12) {
            summaryCard("Bekleyen Brüt", pendingGross, "creditcard.fill", AppTheme.warning)
            summaryCard("Bekleyen POS Neti", pendingNet, "clock.fill", AppTheme.accent)
            summaryCard("Netleşen POS", settledNet, "checkmark.circle.fill", AppTheme.positive)
            summaryCard("Banka Kesintisi", activeCommission, "percent", AppTheme.accent)
            summaryCard("Net Kâr", activeProfit, "chart.line.uptrend.xyaxis", activeProfit >= 0 ? AppTheme.positive : AppTheme.negative)
        }
    }

    private func summaryCard(_ title: String, _ amount: Double, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.14)))
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.caption).foregroundColor(AppTheme.textSecondary)
                Text(currency(amount)).font(.headline).fontWeight(.bold).lineLimit(1)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border))
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Filtreler", systemImage: "line.3.horizontal.decrease.circle")
                    .font(.headline)
                Spacer()
                Button("Temizle") {
                    statusFilter = .all
                    dateFilter = .all
                    selectedPOSCompanyID = nil
                    selectedBankID = nil
                }
                .foregroundColor(AppTheme.accent)
                .buttonStyle(.plain)
            }

            Picker("Durum", selection: $statusFilter) {
                ForEach(POSStatusFilter.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(SegmentedPickerStyle())

            HStack(spacing: 12) {
                filterPicker("Tarih", selection: $dateFilter) {
                    ForEach(POSDateFilter.allCases) { Text($0.title).tag($0) }
                }
                filterPicker("POS Şirketi", selection: $selectedPOSCompanyID) {
                    Text("Tüm POS Şirketleri").tag(nil as UUID?)
                    ForEach(store.companies) { Text($0.name).tag($0.id as UUID?) }
                }
                filterPicker("POS Bankası", selection: $selectedBankID) {
                    Text("Tüm Bankalar").tag(nil as UUID?)
                    ForEach(availableBanks) { Text($0.bankName).tag($0.id as UUID?) }
                }
            }

            if dateFilter == .custom {
                HStack {
                    DatePicker("Başlangıç", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("Bitiş", selection: $customEndDate, displayedComponents: .date)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border))
    }

    private func filterPicker<Selection: Hashable, Content: View>(
        _ title: String,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased()).font(.caption2).fontWeight(.semibold).foregroundColor(AppTheme.textSecondary)
            Picker(title, selection: selection, content: content)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
    }

    private var emptySection: some View {
        VStack(spacing: 12) {
            Image(systemName: "creditcard")
                .font(.system(size: 42))
                .foregroundColor(AppTheme.textSecondary)
            Text("Seçili filtrelerde POS işlemi bulunmuyor").font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
    }

    private func transactionCard(_ transaction: POSTransaction) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Text(companyInitial(transaction.companyID))
                        .font(.headline).fontWeight(.bold)
                        .frame(width: 42, height: 42)
                        .background(Circle().fill(AppTheme.accent))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(companyName(transaction.companyID)).font(.headline)
                        Label(store.bankName(for: transaction.posBankID), systemImage: "building.columns.fill")
                            .font(.subheadline).foregroundColor(AppTheme.textSecondary)
                    }
                }
                Spacer()
                statusBadge(transaction.status)
            }

            HStack(spacing: 18) {
                metadata("calendar", dateText(transaction.transactionDate))
                metadata("person.fill", transaction.customerName)
                metadata("number", transaction.reference)
            }

            Divider()

            HStack(spacing: 0) {
                valueCell("Brüt", transaction.posAmount)
                valueCell("Ana Para", transaction.principalAmount)
                valueCell("Banka Kesintisi", transaction.commissionAmount)
                valueCell("POS Neti", transaction.netBankAmount)
                valueCell("Net Kâr", transaction.profitAmount, color: transaction.profitAmount >= 0 ? AppTheme.positive : AppTheme.negative)
            }

            if transaction.status != .cancelled {
                HStack(spacing: 12) {
                    Spacer()
                    if transaction.status == .pending {
                        Button("Düzenle") { editingTransaction = transaction }
                        Button("Netleştir") { settle(transaction) }
                    }
                    Button("İptal Et") { cancel(transaction) }.foregroundColor(AppTheme.negative)
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
    }

    private func metadata(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon).font(.caption).foregroundColor(AppTheme.textSecondary).lineLimit(1)
    }

    private func valueCell(_ title: String, _ value: Double, color: Color = AppTheme.primaryText) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title.uppercased()).font(.caption2).foregroundColor(AppTheme.textSecondary)
            Text(currency(value)).font(.subheadline).fontWeight(.semibold).foregroundColor(color).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statusBadge(_ status: POSTransactionStatus) -> some View {
        Text(statusTitle(status)).font(.caption).fontWeight(.semibold)
            .padding(.horizontal, 11).padding(.vertical, 6)
            .background(Capsule().fill(statusColor(status).opacity(0.16)))
            .foregroundColor(statusColor(status))
    }

    private var availableBanks: [POSBank] {
        guard let companyID = selectedPOSCompanyID else { return store.posBanks }
        return store.banks(for: companyID)
    }

    private var baseFilteredTransactions: [POSTransaction] {
        store.posTransactions.filter {
            (selectedPOSCompanyID == nil || $0.companyID == selectedPOSCompanyID) &&
            (selectedBankID == nil || $0.posBankID == selectedBankID) && matchesDate($0.transactionDate)
        }
    }

    private var filteredTransactions: [POSTransaction] {
        baseFilteredTransactions.filter { statusFilter.matches($0.status) }.sorted { $0.transactionDate > $1.transactionDate }
    }

    private var activeSummaryTransactions: [POSTransaction] { baseFilteredTransactions.filter { $0.status != .cancelled } }
    private var pendingGross: Double { activeSummaryTransactions.filter { $0.status == .pending }.reduce(0) { $0 + $1.posAmount } }
    private var pendingNet: Double { activeSummaryTransactions.filter { $0.status == .pending }.reduce(0) { $0 + $1.netBankAmount } }
    private var settledNet: Double { activeSummaryTransactions.filter { $0.status == .settled }.reduce(0) { $0 + $1.netBankAmount } }
    private var activeCommission: Double { activeSummaryTransactions.reduce(0) { $0 + $1.commissionAmount } }
    private var activeProfit: Double { activeSummaryTransactions.reduce(0) { $0 + $1.profitAmount } }

    private func matchesDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        switch dateFilter {
        case .all: return true
        case .today: return calendar.isDateInToday(date)
        case .week: return calendar.dateInterval(of: .weekOfYear, for: Date())?.contains(date) ?? false
        case .month: return calendar.dateInterval(of: .month, for: Date())?.contains(date) ?? false
        case .year: return calendar.dateInterval(of: .year, for: Date())?.contains(date) ?? false
        case .custom:
            let start = calendar.startOfDay(for: min(customStartDate, customEndDate))
            let lastDay = calendar.startOfDay(for: max(customStartDate, customEndDate))
            let end = calendar.date(byAdding: .day, value: 1, to: lastDay) ?? lastDay
            return date >= start && date < end
        }
    }

    private func handleCreate(_ transaction: POSTransaction) -> FinancialOperationResult {
        let result = store.createPOSTransaction(transaction)
        if case .success = result { newTransactionCompany = nil }
        return result
    }

    private func handleUpdate(_ transaction: POSTransaction) -> FinancialOperationResult {
        let result = store.updatePOSTransactionSafely(transaction)
        if case .success = result { editingTransaction = nil }
        return result
    }

    private func settle(_ transaction: POSTransaction) { handle(store.settlePOSTransaction(transaction.id)) }
    private func cancel(_ transaction: POSTransaction) { handle(store.cancelPOSTransaction(transaction.id)) }
    private func handle(_ result: FinancialOperationResult) {
        if case .failure(let message) = result { errorMessage = message; showError = true }
    }

    private func companyName(_ id: UUID) -> String { store.company(for: id)?.name ?? "Bilinmeyen Şirket" }
    private func companyInitial(_ id: UUID) -> String { companyName(id).trimmingCharacters(in: .whitespaces).first.map(String.init) ?? "?" }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter(); formatter.numberStyle = .currency; formatter.currencyCode = "TRY"; formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: value)) ?? "₺0,00"
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "tr_TR"); formatter.dateFormat = "dd.MM.yyyy · HH:mm"
        return formatter.string(from: date)
    }

    private func statusTitle(_ status: POSTransactionStatus) -> String {
        switch status { case .pending: return "Bekleyen"; case .settled: return "Netleşen"; case .cancelled: return "İptal" }
    }

    private func statusColor(_ status: POSTransactionStatus) -> Color {
        switch status { case .pending: return AppTheme.warning; case .settled: return AppTheme.positive; case .cancelled: return AppTheme.negative }
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
