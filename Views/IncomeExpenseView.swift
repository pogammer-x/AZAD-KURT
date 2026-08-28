import SwiftUI

struct IncomeExpenseView: View {
    @EnvironmentObject var store: AppStore
    @State private var showEntry = false

    var operationalNet: Double {
        store.totalNetPOSProfit + store.manualIncomeTotal - store.manualExpenseTotal
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Gelir / Gider").font(.largeTitle).fontWeight(.bold)
                    Text("Gerçek operasyonel gelir ve giderleri yönetin.")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Yeni Gelir / Gider") { showEntry = true }
                    .buttonStyle(DefaultButtonStyle())
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)]) {
                card("POS Gerçek Net Kâr", store.totalNetPOSProfit)
                card("Manuel Gelir", store.manualIncomeTotal)
                card("Manuel Gider", store.manualExpenseTotal)
                card("Operasyonel Net", operationalNet)
            }

            Text("Ana para giriş ve çıkışları bu hesaplara dahil edilmez.")
                .font(.caption).foregroundColor(.secondary)

            List(store.transactions.sorted { $0.transactionDate > $1.transactionDate }) { transaction in
                HStack {
                    VStack(alignment: .leading) {
                        Text(transaction.title).fontWeight(.semibold)
                        Text(store.company(for: transaction.companyID)?.name ?? "Bilinmeyen Şirket")
                            .font(.caption).foregroundColor(.secondary)
                        if !transaction.note.isEmpty {
                            Text(transaction.note).font(.caption).foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Text(transaction.type == .income ? "+\(currency(transaction.amount))" : "-\(currency(transaction.amount))")
                        .foregroundColor(
                            transaction.type == .income
                                ? AppTheme.positive
                                : AppTheme.negative
                        )
                        .fontWeight(.bold)
                }
            }
        }
        .padding(28)
        .sheet(isPresented: $showEntry) {
            ManualTransactionView { result in
                if result == .success { showEntry = false }
            }
            .environmentObject(store)
        }
    }

    func card(_ title: String, _ value: Double) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(currency(value)).font(.title2).fontWeight(.bold)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.card))
    }

    func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.currencyCode = "TRY"
        return formatter.string(from: NSNumber(value: value)) ?? "₺0,00"
    }
}

struct ManualTransactionView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode
    let onSave: (FinancialOperationResult) -> Void
    @State private var type: TransactionType = .income
    @State private var companyID: UUID?
    @State private var title = ""
    @State private var amountText = ""
    @State private var note = ""
    @State private var operationID = UUID()
    @State private var errorMessage = ""

    var amount: Double {
        Double(amountText.replacingOccurrences(of: ".", with: "").replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        Form {
            Text("Yeni Gelir / Gider").font(.title).fontWeight(.bold)
            Picker("Tür", selection: $type) {
                Text("Gelir").tag(TransactionType.income)
                Text("Gider").tag(TransactionType.expense)
            }
            .pickerStyle(.segmented)
            Picker("Şirket", selection: $companyID) {
                ForEach(store.companies) { Text($0.name).tag($0.id as UUID?) }
            }
            TextField("Başlık", text: $title)
            TextField("Tutar", text: $amountText)
            TextField("Açıklama", text: $note)
            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(AppTheme.negative)
            }
            HStack {
                Button("Vazgeç") { presentationMode.wrappedValue.dismiss() }
                Spacer()
                Button("Kaydet") {
                    guard let companyID = companyID else { return }
                    let result = store.recordManualTransaction(
                        id: operationID,
                        companyID: companyID,
                        type: type,
                        title: title,
                        amount: amount,
                        note: note
                    )
                    if case .failure(let message) = result { errorMessage = message }
                    onSave(result)
                }
                .disabled(companyID == nil || title.isEmpty || amount <= 0)
            }
        }
        .padding(24).frame(width: 500)
        .onAppear { companyID = companyID ?? store.companies.first?.id }
    }
}

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    @State private var saved = false
    @State private var deletionPassword = ""
    @State private var showPasswordSheet = false
    @State private var deletionAlert: SettingsDeletionAlert? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Ayarlar").font(.largeTitle).fontWeight(.bold)
            Text("Veri ve uygulama durumu").foregroundColor(.secondary)
            GroupBox(label: Text("Kalıcı Veri Özeti")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Şirket: \(store.companies.count)")
                    Text("POS Bankası: \(store.posBanks.count)")
                    Text("POS İşlemi: \(store.posTransactions.count)")
                    Text("Alacak: \(store.receivables.count)")
                    Text("Ödeme: \(store.payments.count)")
                    Text("Finans Hareketi: \(store.balanceTransactions.count)")
                    Text("Fatura: \(store.invoices.count)")
                    Text("Gelir / Gider: \(store.transactions.count)")
                }.padding(10)
            }
            Button("Verileri Şimdi Kaydet") { store.save(); saved = true }
            if saved {
                Text("Veriler kaydedildi.").foregroundColor(AppTheme.positive)
            }

            GroupBox(label: Text("Veri Yönetimi")) {
                VStack(alignment: .leading, spacing: 10) {
                    Button("Tüm Verileri Sil") {
                        deletionAlert = .initialConfirmation
                    }
                    .buttonStyle(PlainButtonStyle())
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.75))
                    )

                    Text("Varsayılan silme şifresi: \(AppStore.defaultDeletionPassword)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
        .padding(28)
        .sheet(isPresented: $showPasswordSheet) {
            deletionPasswordView
        }
        .alert(item: $deletionAlert) { alert in
            deletionAlertView(alert)
        }
    }


    private var deletionPasswordView: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Silme Şifresi")
                .font(.title2)
                .fontWeight(.bold)

            Text("Devam etmek için 4 haneli silme şifresini girin.")
                .foregroundColor(.secondary)

            SecureField("4 haneli şifre", text: $deletionPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Button("Vazgeç") {
                    showPasswordSheet = false
                    deletionPassword = ""
                }

                Spacer()

                Button("Devam Et") {
                    validateDeletionPassword()
                }
                .disabled(deletionPassword.count != 4)
            }
        }
        .padding(24)
        .frame(width: 420)
    }


    private func validateDeletionPassword() {
        showPasswordSheet = false

        if store.isValidDeletionPassword(deletionPassword) {
            deletionAlert = .finalConfirmation
        } else {
            deletionPassword = ""
            deletionAlert = .wrongPassword
        }
    }


    private func deleteAllUserData() {
        let result = store.deleteAllUserData(
            password: deletionPassword
        )
        deletionPassword = ""

        switch result {
        case .success:
            saved = false
            deletionAlert = .success
        case .failure:
            deletionAlert = .wrongPassword
        }
    }


    private func deletionAlertView(
        _ alert: SettingsDeletionAlert
    ) -> Alert {
        switch alert {
        case .initialConfirmation:
            return Alert(
                title: Text("Tüm Verileri Sil"),
                message: Text("Bu işlem tüm şirketleri, POS işlemlerini, POS bankalarını, alacakları, ödemeleri, ana para hareketlerini, gelir/gider kayıtlarını, faturaları ve finansal geçmişi kalıcı olarak silecektir. Bu işlem geri alınamaz."),
                primaryButton: .cancel(Text("Vazgeç")),
                secondaryButton: .destructive(Text("Devam Et")) {
                    deletionPassword = ""
                    showPasswordSheet = true
                }
            )
        case .wrongPassword:
            return Alert(
                title: Text("Şifre yanlış."),
                dismissButton: .default(Text("Tamam"))
            )
        case .finalConfirmation:
            return Alert(
                title: Text("Son Onay"),
                message: Text("Son onay: Tüm kullanıcı verileri kalıcı olarak silinecek. Emin misiniz?"),
                primaryButton: .cancel(Text("İptal")) {
                    deletionPassword = ""
                },
                secondaryButton: .destructive(Text("Tümünü Sil")) {
                    deleteAllUserData()
                }
            )
        case .success:
            return Alert(
                title: Text("Tüm veriler silindi."),
                dismissButton: .default(Text("Tamam"))
            )
        }
    }
}


private enum SettingsDeletionAlert: String, Identifiable {
    case initialConfirmation
    case wrongPassword
    case finalConfirmation
    case success

    var id: String {
        rawValue
    }
}
