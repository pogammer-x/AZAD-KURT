import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var capitalAction: CapitalAction?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Ana Panel")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Tüm şirketlerin finansal durumunu tek ekrandan yönetin.")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Ana Para Ekle") { capitalAction = .add }
                        .buttonStyle(PlainButtonStyle())
                        .accentButton()
                    Button("Ana Para Çıkar") { capitalAction = .withdraw }
                        .foregroundColor(AppTheme.textPrimary)
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220), spacing: 16)],
                    spacing: 16
                ) {
                    summaryCard("TOPLAM BAKİYE", store.totalCashBalance, "banknote.fill", "Tüm nakit hesapları")
                    summaryCard("TOPLAM ALACAK", store.receivablesTotal, "arrow.down.left", "Açık alacak bakiyesi")
                    summaryCard("TOPLAM ÖDEME / BORÇ", store.paymentsTotal, "arrow.up.right", "Gerçekleşen ödemeler")
                    summaryCard("NET KÂR", store.netProfit, "chart.line.uptrend.xyaxis", "Güncel finansal sonuç")
                }

                HStack(alignment: .top, spacing: 16) {
                    companyBalancesSection
                    recentTransactionsSection
                }

                HStack(alignment: .top, spacing: 16) {
                    pendingPOSSection
                    financialOverviewSection
                }
            }
            .padding(28)
        }
        .background(AppTheme.background.edgesIgnoringSafeArea(.all))
        .corporateScreen()
        .sheet(item: $capitalAction) { action in
            CapitalManagementView(
                action: action,
                companies: store.companies,
                banks: store.posBanks,
                onSave: { target, amount, description, movementID in
                    handleCapital(
                        action: action,
                        target: target,
                        amount: amount,
                        description: description,
                        movementID: movementID
                    )
                }
            )
        }
    }

    func summaryCard(
        _ title: String,
        _ amount: Double,
        _ icon: String,
        _ subtitle: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.accent))
                Spacer()
            }
            Text(title).font(.caption).foregroundColor(AppTheme.textSecondary)
            Text(currency(amount)).font(.title2).fontWeight(.bold)
            Text(subtitle).font(.caption).foregroundColor(AppTheme.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
    }

    var companyBalancesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Şirket Bakiyeleri").font(.title3).fontWeight(.bold)
            ForEach(store.companies) { company in
                HStack {
                    Text(String(company.name.prefix(1)).uppercased())
                        .fontWeight(.bold)
                        .frame(width: 32, height: 32)
                        .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.accentMuted))
                    Text(company.name).fontWeight(.semibold)
                    Spacer()
                    Text(currency(company.balance)).fontWeight(.bold)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .premiumCard()
    }

    var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Son İşlemler").font(.title3).fontWeight(.bold)
            ForEach(Array(store.balanceTransactions.sorted { $0.date > $1.date }.prefix(4))) { movement in
                HStack {
                    Image(systemName: movement.amount >= 0 ? "arrow.down.left" : "arrow.up.right")
                        .foregroundColor(movement.amount >= 0 ? AppTheme.positive : AppTheme.negative)
                    Text(movement.description).lineLimit(1)
                    Spacer()
                    Text(currency(movement.amount)).fontWeight(.semibold)
                }
            }
            if store.balanceTransactions.isEmpty {
                Text("Henüz finansal hareket yok.").foregroundColor(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .premiumCard()
    }

    var pendingPOSSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bekleyen POS").font(.title3).fontWeight(.bold)
            Text(currency(store.pendingPOSTotal)).font(.title).fontWeight(.bold)
            Text("Netleşmeyi bekleyen POS işlemleri")
                .foregroundColor(AppTheme.textSecondary)
            ProgressView(value: store.pendingPOSTotal, total: max(store.totalPOSVolume, 1))
                .accentColor(AppTheme.accent)
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .premiumCard(secondary: true)
    }

    var financialOverviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Finansal Özet").font(.title3).fontWeight(.bold)
            HStack(spacing: 8) {
                overviewBar("Bakiye", store.totalCashBalance, AppTheme.textPrimary)
                overviewBar("Alacak", store.receivablesTotal, AppTheme.positive)
                overviewBar("Ödeme", store.paymentsTotal, AppTheme.negative)
                overviewBar("Kâr", store.netProfit, AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
        .premiumCard(secondary: true)
    }

    func overviewBar(_ title: String, _ value: Double, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Rectangle().fill(color).frame(height: max(4, min(34, CGFloat(abs(value) / 10000))))
            Text(title).font(.caption).foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
    }

    func handleCapital(
        action: CapitalAction,
        target: CapitalAccountTarget,
        amount: Double,
        description: String,
        movementID: UUID
    ) -> FinancialOperationResult {
        let result: FinancialOperationResult
        switch action {
        case .add:
            result = store.addCapital(
                amount: amount,
                companyID: target.companyID,
                posBankID: target.posBankID,
                movementID: movementID,
                description: description
            )
        case .withdraw:
            result = store.withdrawCapital(
                amount: amount,
                companyID: target.companyID,
                posBankID: target.posBankID,
                movementID: movementID,
                description: description
            )
        }

        if case .success = result {
            capitalAction = nil
        }
        return result
    }

    func currency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "0") ₺"
    }
}

enum CapitalAction: String, Identifiable {
    case add
    case withdraw
    var id: String { rawValue }
    var title: String { self == .add ? "Ana Para Ekle" : "Ana Para Çıkar" }
}

struct CapitalAccountTarget: Identifiable, Hashable {
    var id: String
    var companyID: UUID
    var posBankID: UUID?
    var title: String
    var balance: Double
}

struct CapitalManagementView: View {
    let action: CapitalAction
    let companies: [Company]
    let banks: [POSBank]
    let onSave: (CapitalAccountTarget, Double, String, UUID) -> FinancialOperationResult

    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedTargetID = ""
    @State private var amountText = ""
    @State private var description = ""
    @State private var movementID = UUID()
    @State private var errorMessage = ""
    @State private var showError = false

    var targets: [CapitalAccountTarget] {
        let companyTargets = companies.map {
            CapitalAccountTarget(
                id: "company-\($0.id.uuidString)",
                companyID: $0.id,
                title: "\($0.name) · Şirket Hesabı",
                balance: $0.balance
            )
        }
        // The ordinary capital flow always changes the selected company's cash
        // balance. POS bank balances are populated only by explicit POS flows.
        return companyTargets
    }

    var selectedTarget: CapitalAccountTarget? {
        targets.first { $0.id == selectedTargetID }
    }

    var amount: Double {
        MoneyMath.parseTurkishAmount(amountText) ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(action.title).font(.title).fontWeight(.bold)
            Text("Ana para hareketleri gelir, gider veya kâr oluşturmaz.")
                .foregroundColor(.secondary)

            Picker("Hesap", selection: $selectedTargetID) {
                Text("Hesap Seçin").tag("")
                ForEach(targets) { target in
                    Text(target.title).tag(target.id)
                }
            }

            if let target = selectedTarget {
                Text("Kullanılabilir Bakiye: \(currency(target.balance))")
                    .fontWeight(.semibold)
            }

            TextField("Tutar", text: $amountText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Açıklama (zorunlu)", text: $description)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Vazgeç") { presentationMode.wrappedValue.dismiss() }
                Spacer()
                Button(action.title) {
                    guard let target = selectedTarget else { return }
                    let result = onSave(
                        target,
                        amount,
                        description.trimmingCharacters(in: .whitespacesAndNewlines),
                        movementID
                    )
                    switch result {
                    case .success:
                        amountText = ""
                        description = ""
                        movementID = UUID()
                        presentationMode.wrappedValue.dismiss()
                    case .failure(let message):
                        errorMessage = message
                        showError = true
                    }
                }
                .buttonStyle(DefaultButtonStyle())
                .disabled(
                    selectedTarget == nil ||
                    amount <= 0 ||
                    description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .padding(24)
        .frame(width: 520)
        .onAppear {
            if selectedTargetID.isEmpty {
                selectedTargetID = targets.first?.id ?? ""
            }
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Ana Para İşlemi Hatası"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    func companyName(_ id: UUID) -> String {
        companies.first { $0.id == id }?.name ?? "Bilinmeyen Şirket"
    }

    func currency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.maximumFractionDigits = 2
        return "\(formatter.string(from: NSNumber(value: amount)) ?? "0") ₺"
    }
}
