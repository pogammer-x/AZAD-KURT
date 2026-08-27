import SwiftUI

struct CompanyDetailView: View {
    
    let company: Company
    @EnvironmentObject var store: AppStore
    @State private var posBanks: [POSBank] = []
    @State private var posTransactions: [POSTransaction] = []
    
    @State private var showAddPOSBank = false
    @State private var showNewPOSTransaction = false
    
    @State private var editingTransaction: POSTransaction? = nil
    @State private var deletingTransaction: POSTransaction? = nil
    
    @State private var editingBank: POSBank? = nil
    @State private var showEditPOSBank = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            Divider()
            
            bankHeaderSection
            bankListSection
            
            Divider()
            
            transactionHeaderSection
            transactionListSection
            
            Spacer()
        }
        .padding(25)
        
        .onAppear {
            posBanks = store.posBanks.filter {
                $0.companyID == company.id
            }
            
            posTransactions = store.posTransactions.filter {
                $0.companyID == company.id
            }
        }
        
        // POS BANKASI EKLE
        .sheet(isPresented: $showAddPOSBank) {
            AddPOSBankView(
                company: company,
                onSave: { newBank in
                    posBanks.append(newBank)
                    store.posBanks.append(newBank)
                    showAddPOSBank = false
                },
                onCancel: {
                    showAddPOSBank = false
                }
            )
        }
        
        // POS BANKASI DÜZENLE
        .sheet(item: $editingBank) { bank in
            EditPOSBankView(
                bank: bank,
                onSave: { updatedBank in
                    if let index = posBanks.firstIndex(where: { $0.id == updatedBank.id }) {
                        posBanks[index] = updatedBank
                    }
                    
                    if let index = store.posBanks.firstIndex(where: { $0.id == updatedBank.id }) {
                        store.posBanks[index] = updatedBank
                    }
                    
                    editingBank = nil
                },
                onCancel: {
                    editingBank = nil
                }
            )
        }
        
        // YENİ POS İŞLEMİ
        .sheet(isPresented: $showNewPOSTransaction) {
            POSTransactionView(
                company: company,
                posBanks: posBanks,
                editingTransaction: nil,
                onSave: { newTransaction in
                    posTransactions.append(newTransaction)
                    store.posTransactions.append(newTransaction)
                    showNewPOSTransaction = false
                }
            )
        }
        
        // POS İŞLEMİ DÜZENLE
        .sheet(item: $editingTransaction) { transaction in
            POSTransactionView(
                company: company,
                posBanks: posBanks,
                editingTransaction: transaction,
                onSave: { updatedTransaction in
                    updateTransaction(updatedTransaction)
                    editingTransaction = nil
                }
            )
        }
        
        // SİLME ONAYI
        .alert(
            item: $deletingTransaction
        ) { transaction in
            Alert(
                title: Text("POS İşlemini Sil"),
                message: Text(
                    "\(transaction.customerName) adına kayıtlı \(money(transaction.posAmount)) tutarındaki işlemi silmek istediğinize emin misiniz?"
                ),
                primaryButton: .destructive(
                    Text("Sil")
                ) {
                    deleteTransaction(transaction)
                },
                secondaryButton: .cancel(
                    Text("Vazgeç")
                )
            )
        }
    }
    // MARK: - ŞİRKET BAŞLIK
    
    var headerSection: some View {
        
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            
            Text(company.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Şirket Yönetim Paneli")
                .foregroundColor(.secondary)
        }
    }
    
    
    // MARK: - POS BANKALARI BAŞLIK
    
    var bankHeaderSection: some View {
        
        HStack {
            
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                
                Text("POS Bankaları")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(
                    "\(posBanks.count) / 5 POS tanımlı"
                )
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("+ POS Bankası Ekle") {
                
                if posBanks.count < 5 {
                    
                    showAddPOSBank = true
                }
            }
            .disabled(
                posBanks.count >= 5
            )
        }
    }
    
    
    // MARK: - POS BANKA LİSTESİ
    
    var bankListSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            if posBanks.isEmpty {

                Text("Henüz POS bankası eklenmedi.")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)

            } else {

                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 300), spacing: 16)
                    ],
                    spacing: 16
                ) {

                    ForEach(posBanks) { bank in

                        let totalPOS = store.totalPOSAmount(
                            for: bank.id,
                            companyID: company.id
                        )

                        let deduction = store.totalBankDeduction(
                            for: bank.id,
                            companyID: company.id
                        )

                        let netAmount = totalPOS - deduction

                        VStack(alignment: .leading, spacing: 16) {

                            // BANKA BAŞLIK
                            HStack {

                                VStack(alignment: .leading, spacing: 5) {

                                    Text(bank.bankName)
                                        .font(.title2)
                                        .fontWeight(.bold)

                                    Text(bank.isActive ? "Aktif" : "Pasif")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button("Düzenle") {
                                    editingBank = bank
                                }
                                .buttonStyle(.bordered)
                            }

                            Divider()

                            // ORANLAR
                            HStack(spacing: 30) {

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Tek Çekim")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text("%\(rateText(bank.singlePaymentRate))")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Taksit Oranları")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text("\(bank.installmentRates.count) oran")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }

                                Spacer()
                            }

                            Divider()

                            // FİNANS ÖZETİ
                            HStack(spacing: 24) {

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Toplam POS")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(money(totalPOS))
                                        .font(.headline)
                                }

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Kesinti")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(money(deduction))
                                        .font(.headline)
                                }

                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Net")
                                        .font(.caption)
                                        .foregroundColor(.secondary)

                                    Text(money(netAmount))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }

                                Spacer()
                            }
                        }
                        .padding(20)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 210,
                            alignment: .topLeading
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    Color.primary.opacity(0.10),
                                    lineWidth: 1
                                )
                        )
                    }
                }
            }
        }
    }// MARK: - POS İŞLEMLERİ BAŞLIK

var transactionHeaderSection: some View {
    
    HStack {
        
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            
            Text("POS İşlemleri")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(
                "\(posTransactions.count) işlem"
            )
                .foregroundColor(.secondary)
        }
        
        Spacer()
        
        Button("+ Yeni POS İşlemi") {
            
            if !posBanks.isEmpty {
                
                showNewPOSTransaction = true
            }
        }
        .disabled(
            
            posBanks.isEmpty
        )
    }
}


// MARK: - POS İŞLEM LİSTESİ

var transactionListSection: some View {
    
    VStack(
        alignment: .leading,
        spacing: 8
    ) {
        
        if posTransactions.isEmpty {
            
            Text(
                "Henüz POS işlemi yok."
            )
                .foregroundColor(.secondary)
            
        } else {
            
            List {
                
                ForEach(posTransactions) { transaction in
                    
                    transactionRow(
                        transaction
                    )
                }
            }
            .frame(
                minHeight: 280
            )
        }
    }
}


// MARK: - İŞLEM SATIRI

func transactionRow(
    _ transaction: POSTransaction
) -> some View {
    
    VStack(
        alignment: .leading,
        spacing: 8
    ) {
        
        HStack {
            
            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                
                Text(
                    transaction.customerName
                )
                    .font(.headline)
                
                Text(
                    bankNameFor(
                        transaction.posBankID
                    )
                )
                    .foregroundColor(
                        .secondary
                    )
            }
            
            Spacer()
            
            Text(
                money(
                    transaction.posAmount
                )
            )
                .fontWeight(.bold)
        }
        
        
        Divider()
        
        
        HStack {
            
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                
                Text(
                    "Ana Para: " +
                    money(
                        transaction.principalAmount
                    )
                )
                
                Text(
                    "Banka Komisyonu: " +
                    money(
                        transaction.commissionAmount
                    )
                )
                
                Text(
                    "Bankadan Net: " +
                    money(
                        transaction.netBankAmount
                    )
                )
                
                Text(
                    "Net Kâr: " +
                    money(
                        transaction.profitAmount
                    )
                )
                    .fontWeight(.bold)
                
                Text(
                    "Komisyon Oranı: %" +
                    rateText(
                        transaction.commissionRate
                    )
                )
                
                Text(
                    transaction.installmentCount == 1
                    ? "Tek Çekim"
                    : "\(transaction.installmentCount) Taksit"
                )
            }
            .font(.caption)
            
            Spacer()
            
            
            VStack(
                spacing: 8
            ) {
                
                Button("Düzenle") {
                    
                    editingTransaction =
                    transaction
                }
                
                Button("Hesaba Geçti") {
                    var updated = transaction
                    updated.status = .settled
                    updated.settlementDate = Date()
                    updateTransaction(updated)
                }
                Button("Sil") {
                    
                    deletingTransaction =
                    transaction
                }
            }
        }
    }
    .padding(.vertical, 8)
}


// MARK: - İŞLEM GÜNCELLE

func updateTransaction(
    _ updated: POSTransaction
) {
    
    if let index =
        posTransactions.firstIndex(
            where: {
                $0.id == updated.id
            }
        ) {
        
        posTransactions[index] =
        
        updated
        store.updatePOSTransaction(updated)
        
    }
}


// MARK: - İŞLEM SİL

func deleteTransaction(
    _ transaction: POSTransaction
) {
    store.posTransactions.removeAll {
        $0.id == transaction.id
    }
    posTransactions.removeAll {
        
        $0.id == transaction.id
    }
    
    deletingTransaction = nil
    
}


// MARK: - BANKA ADI BUL

func bankNameFor(
    _ bankID: UUID
) -> String {
    
    for bank in posBanks {
        
        if bank.id == bankID {
            
            return bank.bankName
        }
    }
    
    return "Bilinmeyen Banka"
}


// MARK: - PARA FORMAT

func money(
    _ value: Double
) -> String {
    
    let formatter =
    NumberFormatter()
    
    formatter.numberStyle =
        .decimal
    
    formatter.groupingSeparator =
    "."
    
    formatter.decimalSeparator =
    ","
    
    formatter.minimumFractionDigits =
    2
    
    formatter.maximumFractionDigits =
    2
    
    let formatted =
    formatter.string(
        from: NSNumber(
            value: value
        )
    ) ?? "0,00"
    
    return "₺" + formatted
}


// MARK: - ORAN FORMAT

func rateText(
    _ value: Double
) -> String {
    
    return String(
        format: "%.2f",
        value
    )
}




// =====================================================
// MARK: - POS BANKASI EKLEME EKRANI
// =====================================================

struct AddPOSBankView: View {
    
    let company: Company
    
    let onSave: (POSBank) -> Void
    let onCancel: () -> Void
    
    @State private var bankName: String = ""
    
    @State private var rateTexts: [String] =
    Array(
        repeating: "",
        count: 18
    )
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            header
            
            Divider()
            
            ScrollView {
                
                VStack(
                    alignment: .leading,
                    spacing: 15
                ) {
                    
                    bankNameSection
                    
                    Divider()
                    
                    Text(
                        "Taksit Komisyon Oranları"
                    )
                        .font(.headline)
                    
                    Text(
                        "Her taksit sayısına farklı oran tanımlayabilirsiniz."
                    )
                        .font(.caption)
                        .foregroundColor(
                            .secondary
                        )
                    
                    rateList
                }
                .padding(20)
            }
            
            Divider()
            
            bottomButtons
        }
        .frame(
            width: 500,
            height: 650
        )
    }
    
    
    // MARK: BAŞLIK
    
    var header: some View {
        
        HStack {
            
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                
                Text("POS Bankası Ekle")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(company.name)
                    .foregroundColor(
                        .secondary
                    )
            }
            
            Spacer()
        }
        .padding(20)
    }
    
    
    // MARK: BANKA ADI
    
    var bankNameSection: some View {
        
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            
            Text("Banka Adı")
                .font(.headline)
            
            TextField(
                "Örn: VakıfBank",
                text: $bankName
            )
                .textFieldStyle(
                    RoundedBorderTextFieldStyle()
                )
        }
    }
    
    
    // MARK: ORAN LİSTESİ
    
    var rateList: some View {
        
        VStack(spacing: 10) {
            
            ForEach(
                1...18,
                id: \.self
            ) { installment in
                
                rateRow(
                    installment:
                        installment
                )
            }
        }
    }
    
    
    // MARK: ORAN SATIRI
    
    func rateRow(
        installment: Int
    ) -> some View {
        
        HStack {
            
            Text(
                installment == 1
                ? "Tek Çekim"
                : "\(installment) Taksit"
            )
                .frame(
                    width: 120,
                    alignment: .leading
                )
            
            TextField(
                "Oran %",
                text: rateBinding(
                    installment:
                        installment
                )
            )
                .textFieldStyle(
                    RoundedBorderTextFieldStyle()
                )
        }
    }
    
    
    // MARK: BINDING
    
    func rateBinding(
        installment: Int
    ) -> Binding<String> {
        
        let index =
        installment - 1
        
        return Binding<String>(
            
            get: {
                
                if index >= 0 &&
                    index < rateTexts.count {
                    
                    return rateTexts[index]
                }
                
                return ""
            },
            
            set: { value in
                
                if index >= 0 &&
                    index < rateTexts.count {
                    
                    rateTexts[index] =
                    value
                }
            }
        )
    }
    
    
    // MARK: ALT BUTONLAR
    
    var bottomButtons: some View {
        
        HStack {
            
            Button("İptal") {
                
                onCancel()
            }
            
            Spacer()
            
            Button("Kaydet") {
                
                saveBank()
            }
            .disabled(
                bankName
                    .trimmingCharacters(
                        in:
                                .whitespacesAndNewlines
                    )
                    .isEmpty
            )
        }
        .padding(20)
    }
    
    
    // MARK: BANKAYI KAYDET
    
    func saveBank() {
        
        let cleanName =
        bankName.trimmingCharacters(
            in:
                    .whitespacesAndNewlines
        )
        
        if cleanName.isEmpty {
            return
        }
        
        var installmentRates:
        [Int: Double] = [:]
        
        var installment = 2
        
        while installment <= 18 {
            
            let index =
            installment - 1
            
            if index <
                rateTexts.count {
                
                installmentRates[
                    installment
                ] =
                convertRate(
                    rateTexts[index]
                )
            }
            
            installment += 1
        }
        
        let singleRate =
        convertRate(
            rateTexts[0]
        )
        
        let newBank =
        POSBank(
            companyID:
                company.id,
            
            bankName:
                cleanName,
            
            singlePaymentRate:
                singleRate,
            
            installmentRates:
                installmentRates
        )
        
        onSave(
            newBank
        )
    }
    
    
    // MARK: ORAN ÇEVİR
    
    func convertRate(
        _ text: String
    ) -> Double {
        
        let clean =
        text.replacingOccurrences(
            of: ",",
            with: "."
        )
        
        return Double(clean) ?? 0
    }
}
}
