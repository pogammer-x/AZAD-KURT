import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: AppStore
    @State private var capitalAction: CapitalAction?
    @State private var errorMessage = ""
    @State private var showError = false

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
                        .buttonStyle(.borderedProminent)
                    Button("Ana Para Çıkar") { capitalAction = .withdraw }
                }

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220), spacing: 16)],
                    spacing: 16
                ) {
                    summaryCard("Ana Para", store.totalCapital, "tray.and.arrow.down.fill")
                    summaryCard("Toplam Kasa", store.totalCashBalance, "banknote.fill")
                    summaryCard("Toplam Alacak", store.receivablesTotal, "arrow.down.circle.fill")
                    summaryCard("Toplam Tahsilat", store.paymentsTotal, "arrow.up.circle.fill")
                    summaryCard("Bekleyen POS", store.pendingPOSTotal, "clock.fill")
                    summaryCard("Netleşen POS", store.settledPOSTotal, "checkmark.circle.fill")
                    summaryCard("Toplam POS Brüt", store.totalPOSVolume, "creditcard.fill")
                    summaryCard("Toplam Komisyon", store.totalCommission, "percent")
                    summaryCard("Toplam Brüt Kâr", store.totalGrossPOSProfit, "chart.bar.fill")
                    summaryCard("Toplam Net Kâr", store.totalNetPOSProfit, "chart.line.uptrend.xyaxis")
                }
            }
            .padding(28)
        }
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
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Ana Para İşlemi Hatası"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }

    func summaryCard(
        _ title: String,
        _ amount: Double,
        _ icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).font(.title3)
                Spacer()
            }
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(currency(amount)).font(.title2).fontWeight(.bold)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
    }

    func handleCapital(
        action: CapitalAction,
        target: CapitalAccountTarget,
        amount: Double,
        description: String,
        movementID: UUID
    ) {
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

        switch result {
        case .success:
            capitalAction = nil
        case .failure(let message):
            errorMessage = message
            showError = true
        }
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
    let onSave: (CapitalAccountTarget, Double, String, UUID) -> Void

    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedTargetID = ""
    @State private var amountText = ""
    @State private var description = ""
    @State private var movementID = UUID()

    var targets: [CapitalAccountTarget] {
        let companyTargets = companies.map {
            CapitalAccountTarget(
                id: "company-\($0.id.uuidString)",
                companyID: $0.id,
                title: "\($0.name) · Şirket Hesabı",
                balance: $0.balance
            )
        }
        let bankTargets = banks.map {
            CapitalAccountTarget(
                id: "bank-\($0.id.uuidString)",
                companyID: $0.companyID,
                posBankID: $0.id,
                title: "\(companyName($0.companyID)) · \($0.bankName)",
                balance: $0.balance
            )
        }
        return companyTargets + bankTargets
    }

    var selectedTarget: CapitalAccountTarget? {
        targets.first { $0.id == selectedTargetID }
    }

    var amount: Double {
        Double(
            amountText
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        ) ?? 0
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
                .textFieldStyle(.roundedBorder)
            TextField("Açıklama (zorunlu)", text: $description)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Vazgeç") { presentationMode.wrappedValue.dismiss() }
                Spacer()
                Button(action.title) {
                    guard let target = selectedTarget else { return }
                    onSave(
                        target,
                        amount,
                        description.trimmingCharacters(in: .whitespacesAndNewlines),
                        movementID
                    )
                }
                .buttonStyle(.borderedProminent)
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
