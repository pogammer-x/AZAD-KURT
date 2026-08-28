import SwiftUI

enum ReportDateSelection: String, CaseIterable, Identifiable {
    case today, week, month, year, custom

    var id: String { rawValue }
    var title: String {
        switch self {
        case .today: return "Bugün"
        case .week: return "Bu Hafta"
        case .month: return "Bu Ay"
        case .year: return "Bu Yıl"
        case .custom: return "Özel Tarih"
        }
    }
}

struct ReportingPeriodResolver {
    static func interval(
        selection: ReportDateSelection,
        customStart: Date,
        customEnd: Date,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DateInterval {
        if selection == .custom {
            let start = calendar.startOfDay(for: min(customStart, customEnd))
            let endDay = calendar.startOfDay(for: max(customStart, customEnd))
            let end = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
            return DateInterval(start: start, end: end)
        }

        let component: Calendar.Component
        switch selection {
        case .today: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        case .year: component = .year
        case .custom: component = .day
        }
        return calendar.dateInterval(of: component, for: now) ??
            DateInterval(start: now, end: now)
    }
}

struct InvoicesView: View {
    @EnvironmentObject var store: AppStore

    @State private var selectedCompanyID: UUID?
    @State private var dateSelection: ReportDateSelection = .month
    @State private var customStart = Date()
    @State private var customEnd = Date()
    @State private var selectedInvoiceID: UUID?
    @State private var invoiceToConfirm: Invoice?
    @State private var errorMessage = ""
    @State private var showError = false

    var period: DateInterval {
        ReportingPeriodResolver.interval(
            selection: dateSelection,
            customStart: customStart,
            customEnd: customEnd
        )
    }

    var selectedInvoice: Invoice? {
        store.invoices.first { $0.id == selectedInvoiceID }
    }

    var currentSummary: FinancialReportSummary {
        store.reportSummary(
            companyID: selectedCompanyID,
            periodStart: period.start,
            periodEnd: period.end
        )
    }

    var displayedInvoices: [Invoice] {
        store.invoices
            .filter { selectedCompanyID == nil || $0.companyID == selectedCompanyID }
            .sorted { $0.periodStart > $1.periodStart }
    }

    var detailTransactions: [POSTransaction] {
        guard let invoice = selectedInvoice else { return [] }
        return store.reportTransactions(
            companyID: invoice.companyID,
            periodStart: invoice.periodStart,
            periodEnd: invoice.periodEnd
        ).sorted { $0.transactionDate > $1.transactionDate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                filters
                summaryCards(currentSummary)
                actions
                invoiceList
                if let invoice = selectedInvoice {
                    invoiceDetail(invoice)
                }
            }
            .padding(28)
        }
        .onAppear {
            if selectedCompanyID == nil {
                selectedCompanyID = store.companies.first?.id
            }
        }
        .sheet(item: $invoiceToConfirm) { invoice in
            InvoiceConfirmationView(invoice: invoice) { date, number, note in
                handle(
                    store.markInvoiceAsInvoiced(
                        invoice.id,
                        invoiceDate: date,
                        invoiceNumber: number,
                        note: note
                    )
                ) {
                    invoiceToConfirm = nil
                }
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Fatura İşlemi Hatası"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Faturalar").font(.largeTitle).fontWeight(.bold)
            Text("Şirketlerin dönemsel POS brüt hacmini ve fatura durumunu yönetin.")
                .foregroundColor(.secondary)
        }
    }

    var filters: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Picker("Şirket", selection: $selectedCompanyID) {
                    ForEach(store.companies) { company in
                        Text(company.name).tag(company.id as UUID?)
                    }
                }
                Picker("Dönem", selection: $dateSelection) {
                    ForEach(ReportDateSelection.allCases) { option in
                        Text(option.title).tag(option)
                    }
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

    func summaryCards(_ summary: FinancialReportSummary) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 175), spacing: 12)], spacing: 12) {
            metric("Fatura Tutarı / Brüt", summary.grossPOSAmount)
            metric("Ana Para", summary.principalAmount)
            metric("Komisyon", summary.commissionAmount)
            metric("Net POS", summary.netPOSAmount)
            metric("Netleşen", summary.settledAmount)
            metric("Bekleyen", summary.pendingAmount)
            metric("Gerçek Net Kâr", summary.netProfitAmount)
        }
    }

    func metric(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(currency(value)).font(.title3).fontWeight(.bold)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.cardElevated))
    }

    var actions: some View {
        HStack {
            Button("Taslak / Özeti Kaydet") { saveSnapshot() }
            Button("Dönemi Kilitle") { lockCurrentPeriod() }
                .disabled(selectedCompanyID == nil)
            Button("Fatura Kesildi") {
                if let invoice = invoiceForCurrentPeriod() {
                    invoiceToConfirm = invoice
                } else {
                    saveSnapshot(openConfirmation: true)
                }
            }
            .buttonStyle(DefaultButtonStyle())
            .disabled(selectedCompanyID == nil)
            Spacer()
            Text(periodText(period))
                .foregroundColor(.secondary)
        }
    }

    var invoiceList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fatura Kayıtları").font(.title2).fontWeight(.bold)
            ForEach(displayedInvoices) { invoice in
                Button {
                    selectedInvoiceID = invoice.id
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(companyName(invoice.companyID)).fontWeight(.semibold)
                            Text(periodText(DateInterval(start: invoice.periodStart, end: invoice.periodEnd)))
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if invoice.isLocked { Label("Kilitli", systemImage: "lock.fill") }
                        Text(invoiceStatus(invoice.status))
                        Text(currency(invoice.grossPOSAmount)).fontWeight(.bold)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.card))
                }
                .buttonStyle(.plain)
            }
        }
    }

    func invoiceDetail(_ invoice: Invoice) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fatura Detayı").font(.title2).fontWeight(.bold)
            summaryCards(
                FinancialReportSummary(
                    grossPOSAmount: invoice.grossPOSAmount,
                    principalAmount: invoice.principalAmount,
                    commissionAmount: invoice.commissionAmount,
                    netPOSAmount: invoice.netPOSAmount,
                    netProfitAmount: invoice.netProfitAmount,
                    pendingAmount: invoice.pendingAmount,
                    settledAmount: invoice.settledAmount,
                    transactionCount: invoice.transactionCount,
                    cancelledTransactionCount: invoice.cancelledTransactionCount
                )
            )
            ForEach(detailTransactions) { transaction in
                HStack {
                    Text(dateText(transaction.transactionDate)).frame(width: 125, alignment: .leading)
                    Text(transaction.reference).frame(width: 145, alignment: .leading)
                    Text(transaction.customerName).frame(maxWidth: .infinity, alignment: .leading)
                    Text(store.bankName(for: transaction.posBankID)).frame(width: 120, alignment: .leading)
                    Text(currency(transaction.posAmount))
                    Text(currency(transaction.principalAmount))
                    Text(currency(transaction.commissionAmount))
                    Text(currency(transaction.netBankAmount))
                    Text(currency(transaction.profitAmount))
                    Text(statusText(transaction.status))
                }
                .font(.caption)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.card))
            }
        }
    }

    func saveSnapshot(openConfirmation: Bool = false) {
        guard let companyID = selectedCompanyID else { return }
        handle(
            store.saveInvoiceSnapshot(
                companyID: companyID,
                periodStart: period.start,
                periodEnd: period.end
            )
        ) {
            if let invoice = invoiceForCurrentPeriod() {
                selectedInvoiceID = invoice.id
                if openConfirmation { invoiceToConfirm = invoice }
            }
        }
    }

    func lockCurrentPeriod() {
        if invoiceForCurrentPeriod() == nil { saveSnapshot() }
        guard let invoice = invoiceForCurrentPeriod() else { return }
        handle(store.lockInvoice(invoice.id)) { selectedInvoiceID = invoice.id }
    }

    func invoiceForCurrentPeriod() -> Invoice? {
        guard let companyID = selectedCompanyID else { return nil }
        return store.invoices.first {
            $0.companyID == companyID && $0.periodStart == period.start && $0.periodEnd == period.end
        }
    }

    func handle(_ result: FinancialOperationResult, success: () -> Void) {
        switch result {
        case .success: success()
        case .failure(let message): errorMessage = message; showError = true
        }
    }

    func companyName(_ id: UUID) -> String { store.company(for: id)?.name ?? "Bilinmeyen Şirket" }
    func invoiceStatus(_ status: InvoiceStatus) -> String { status == .draft ? "Taslak" : status == .invoiced ? "Fatura Kesildi" : "İptal" }
    func statusText(_ status: POSTransactionStatus) -> String { status == .pending ? "Bekleyen" : status == .settled ? "Netleşen" : "İptal" }
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
    func periodText(_ interval: DateInterval) -> String { "\(dateText(interval.start)) – \(dateText(interval.end))" }
}

struct InvoiceConfirmationView: View {
    let invoice: Invoice
    let onSave: (Date?, String?, String) -> Void
    @Environment(\.presentationMode) private var presentationMode
    @State private var invoiceDate = Date()
    @State private var invoiceNumber = ""
    @State private var note = ""

    var body: some View {
        Form {
            Text("Fatura Kesildi").font(.title).fontWeight(.bold)
            DatePicker("Fatura Tarihi", selection: $invoiceDate, displayedComponents: .date)
            TextField("Fatura Numarası", text: $invoiceNumber)
            TextField("Açıklama / Not", text: $note)
            HStack {
                Button("Vazgeç") { presentationMode.wrappedValue.dismiss() }
                Spacer()
                Button("Kaydet") {
                    onSave(invoiceDate, invoiceNumber.isEmpty ? nil : invoiceNumber, note)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(DefaultButtonStyle())
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}

struct FinancialReportsView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection: ReportDateSelection = .month
    @State private var customStart = Date()
    @State private var customEnd = Date()

    var period: DateInterval {
        ReportingPeriodResolver.interval(selection: selection, customStart: customStart, customEnd: customEnd)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Finansal Raporlar").font(.largeTitle).fontWeight(.bold)
                Picker("Dönem", selection: $selection) {
                    ForEach(ReportDateSelection.allCases) { Text($0.title).tag($0) }
                }
                if selection == .custom {
                    HStack {
                        DatePicker("Başlangıç", selection: $customStart, displayedComponents: .date)
                        DatePicker("Bitiş", selection: $customEnd, displayedComponents: .date)
                    }
                }
                reportSection("Genel Toplam", report: report(nil), companyID: nil)
                ForEach(store.companies) { company in
                    reportSection(
                        company.name,
                        report: report(company.id),
                        companyID: company.id
                    )
                }
            }
            .padding(28)
        }
    }

    func report(_ companyID: UUID?) -> ComprehensiveFinancialReport {
        store.comprehensiveReport(
            companyID: companyID,
            periodStart: period.start,
            periodEnd: period.end
        )
    }

    func reportSection(
        _ title: String,
        report: ComprehensiveFinancialReport,
        companyID: UUID?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title2).fontWeight(.bold)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 10)]) {
                reportMetric("Hesap Bakiyesi", accountBalance(companyID))
                reportMetric("Brüt POS", report.pos.grossPOSAmount)
                reportMetric("Kullanılan Ana Para", report.pos.principalAmount)
                reportMetric("Komisyon", report.pos.commissionAmount)
                reportMetric("Brüt Kâr", report.pos.grossProfitAmount)
                reportMetric("Net Kâr", report.pos.netProfitAmount)
                reportMetric("Bekleyen", report.pos.pendingAmount)
                reportMetric("Netleşen", report.pos.settledAmount)
                reportMetric("Alacak", report.receivableAmount)
                reportMetric("Ödeme", report.paymentAmount)
                reportMetric("Ana Para Girişi", report.capitalInAmount)
                reportMetric("Ana Para Çıkışı", report.capitalOutAmount)
                reportMetric("Manuel Gelir", report.manualIncomeAmount)
                reportMetric("Manuel Gider", report.manualExpenseAmount)
                reportMetric("İşlem", Double(report.pos.transactionCount))
                reportMetric("İptal Adedi", Double(report.pos.cancelledTransactionCount))
            }

            if let companyID {
                ForEach(store.banks(for: companyID)) { bank in
                    HStack {
                        Label(bank.bankName, systemImage: "creditcard.fill")
                        Spacer()
                        Text(numberText(bank.balance) + " ₺")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
    }

    func accountBalance(_ companyID: UUID?) -> Double {
        guard let companyID else { return store.totalCashBalance }
        let companyBalance = store.company(for: companyID)?.balance ?? 0
        return companyBalance + store.banks(for: companyID).reduce(0) { $0 + $1.balance }
    }

    func reportMetric(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(numberText(value)).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func numberText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
