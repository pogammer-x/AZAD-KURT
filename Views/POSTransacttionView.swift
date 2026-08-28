import SwiftUI

struct POSTransactionView: View {

    let company: Company
    let posBanks: [POSBank]
    let fundingCompanies: [Company]
    let editingTransaction: POSTransaction?
    let onSave: (POSTransaction) -> Void

    @State private var selectedBankIndex: Int
    @State private var customerName: String
    @State private var posText: String
    @State private var installmentCount: Int
    @State private var fundingSources: [POSFundingSource]

    @State private var useCustomRate: Bool
    @State private var customRateText: String

    init(
        company: Company,
        posBanks: [POSBank],
        fundingCompanies: [Company],
        editingTransaction: POSTransaction? = nil,
        onSave: @escaping (POSTransaction) -> Void
    ) {

        self.company = company
        self.posBanks = posBanks
        self.fundingCompanies = fundingCompanies
        self.editingTransaction = editingTransaction
        self.onSave = onSave

        var bankIndex = 0

        if let transaction = editingTransaction {

            if let index = posBanks.firstIndex(
                where: {
                    $0.id == transaction.posBankID
                }
            ) {
                bankIndex = index
            }
        }

        _selectedBankIndex =
            State(initialValue: bankIndex)

        _customerName =
            State(
                initialValue:
                    editingTransaction?.customerName ?? ""
            )

        let initialFundingSources: [POSFundingSource]
        if let sources = editingTransaction?.fundingSources,
           !sources.isEmpty {
            initialFundingSources = sources
        } else {
            initialFundingSources = [
                POSFundingSource(
                    companyID: company.id,
                    amount: editingTransaction?.principalAmount ?? 0
                )
            ]
        }
        _fundingSources = State(initialValue: initialFundingSources)

        _posText =
            State(
                initialValue:
                    POSTransactionView.initialMoney(
                        editingTransaction?.posAmount
                    )
            )

        _installmentCount =
            State(
                initialValue:
                    editingTransaction?.installmentCount ?? 1
            )

        _useCustomRate =
            State(initialValue: false)

        _customRateText =
            State(initialValue: "")
    }


    var body: some View {

        VStack(spacing: 0) {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    Text(
                        editingTransaction == nil
                        ? "Yeni POS İşlemi"
                        : "POS İşlemini Düzenle"
                    )
                    .font(.title)
                    .fontWeight(.bold)

                    Text(company.name)
                        .foregroundColor(.secondary)

                    Divider()

                    if posBanks.isEmpty {

                        Text(
                            "Bu şirkete önce POS bankası ekleyin."
                        )
                        .foregroundColor(.secondary)

                    } else {

                        Group {

                            bankSection

                            Divider()

                            customerSection

                            Divider()

                            amountSection
                        }

                        Group {

                            Divider()

                            installmentSection

                            Divider()

                            commissionSection

                            Divider()

                            resultSection
                        }
                    }
                }
                .padding(25)
            }

            if !posBanks.isEmpty {

                Divider()

                Button(
                    editingTransaction == nil
                    ? "İşlemi Kaydet"
                    : "Değişiklikleri Kaydet"
                ) {

                    saveTransaction()
                }
                .disabled(
                    customerName.isEmpty ||
                    principal <= 0 ||
                    posAmount <= 0 ||
                    fundingSources.contains { $0.amount <= 0 }
                )
                .padding(20)
            }
        }
        .frame(
            width: 560,
            height: 680
        )
    }


    // MARK: - BANKA

    var bankSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("POS Bankası")
                .font(.headline)

            Picker(
                "POS Bankası",
                selection: $selectedBankIndex
            ) {

                ForEach(
                    0..<posBanks.count,
                    id: \.self
                ) { index in

                    Text(
                        posBanks[index].bankName
                    )
                    .tag(index)
                }
            }
        }
    }


    // MARK: - KİŞİ

    var customerSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("İşlem Yapılan Kişi / Firma")
                .font(.headline)

            TextField(
                "Ad Soyad / Firma",
                text: $customerName
            )
            .textFieldStyle(
                RoundedBorderTextFieldStyle()
            )
        }
    }


    // MARK: - TUTAR

    var amountSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Verilen Ana Para")
                .font(.headline)

            ForEach($fundingSources) { $source in
                HStack {
                    Picker("Kaynak Şirket", selection: $source.companyID) {
                        ForEach(fundingCompanies) { fundingCompany in
                            Text(fundingCompany.name)
                                .tag(fundingCompany.id)
                        }
                    }

                    TextField(
                        "Tutar",
                        text: fundingAmountBinding(for: source.id)
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                    if fundingSources.count > 1 {
                        Button {
                            fundingSources.removeAll { $0.id == source.id }
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                fundingSources.append(
                    POSFundingSource(
                        companyID: company.id,
                        amount: 0
                    )
                )
            } label: {
                Label("Kaynak Ekle", systemImage: "plus.circle")
            }

            Text("Toplam Ana Para: \(money(principal))")
                .fontWeight(.semibold)

            Text("POS'a Girilen Tutar")
                .font(.headline)

            TextField(
                "Örn: 207.000",
                text: posBinding
            )
            .textFieldStyle(
                RoundedBorderTextFieldStyle()
            )
        }
    }


    // MARK: - TAKSİT

    var installmentSection: some View {

        HStack {

            Text("Taksit Sayısı")
                .font(.headline)

            Spacer()

            Button("-") {

                if installmentCount > 1 {
                    installmentCount -= 1
                }
            }

            Text(
                installmentCount == 1
                ? "Tek Çekim"
                : "\(installmentCount) Taksit"
            )
            .frame(width: 110)

            Button("+") {

                if installmentCount < 18 {
                    installmentCount += 1
                }
            }
        }
    }


    // MARK: - KOMİSYON

    var commissionSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text(
                "Tanımlı oran: %" +
                String(
                    format: "%.2f",
                    bankRate
                )
            )

            Toggle(
                "Bu işlem için oranı değiştir",
                isOn: $useCustomRate
            )

            if useCustomRate {

                TextField(
                    "Özel komisyon oranı (%)",
                    text: $customRateText
                )
                .textFieldStyle(
                    RoundedBorderTextFieldStyle()
                )
            }

            Text(
                "Kullanılan oran: %" +
                String(
                    format: "%.2f",
                    currentRate
                )
            )
            .fontWeight(.bold)
        }
    }


    // MARK: - SONUÇ

    var resultSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("İşlem Özeti")
                .font(.headline)

            resultRow(
                title: "Ana Para",
                value: principal
            )

            resultRow(
                title: "POS Tutarı",
                value: posAmount
            )

            resultRow(
                title: "Banka Komisyonu",
                value: commissionAmount
            )

            resultRow(
                title: "Brüt Kâr",
                value: grossProfitAmount
            )

            resultRow(
                title: "Bankadan Net Gelecek",
                value: netBankAmount
            )

            Divider()

            resultRow(
                title: "Net Kâr",
                value: profitAmount
            )
        }
    }


    // MARK: - OTOMATİK PARA YAZIMI

    var posBinding: Binding<String> {

        Binding<String>(
            get: {
                posText
            },
            set: { newValue in

                posText =
                    formatMoneyInput(
                        newValue
                    )
            }
        )
    }


    func fundingAmountBinding(
        for sourceID: UUID
    ) -> Binding<String> {
        Binding<String>(
            get: {
                guard let source = fundingSources.first(
                    where: { $0.id == sourceID }
                ) else {
                    return ""
                }

                return source.amount > 0
                    ? formatMoneyInput(String(Int(source.amount)))
                    : ""
            },
            set: { newValue in
                guard let index = fundingSources.firstIndex(
                    where: { $0.id == sourceID }
                ) else {
                    return
                }

                fundingSources[index].amount = convertMoney(newValue)
            }
        )
    }


    func formatMoneyInput(
        _ text: String
    ) -> String {

        let digits =
            text.filter {
                $0.isNumber
            }

        if digits.isEmpty {
            return ""
        }

        let number =
            Int(digits) ?? 0

        let formatter =
            NumberFormatter()

        formatter.numberStyle =
            .decimal

        formatter.groupingSeparator =
            "."

        formatter.decimalSeparator =
            ","

        formatter.maximumFractionDigits =
            0

        return formatter.string(
            from: NSNumber(
                value: number
            )
        ) ?? digits
    }


    // MARK: - ORAN

    var bankRate: Double {

        if posBanks.isEmpty {
            return 0
        }

        if selectedBankIndex >=
            posBanks.count {

            return 0
        }

        let bank =
            posBanks[selectedBankIndex]

        return bank.rate(
            for: installmentCount
        )
    }


    var currentRate: Double {

        if useCustomRate {

            return convertRate(
                customRateText
            )
        }

        return bankRate
    }


    // MARK: - HESAPLAMA

    var principal: Double {
        fundingSources.reduce(0) {
            $0 + $1.amount
        }
    }


    var posAmount: Double {

        return convertMoney(
            posText
        )
    }


    var commissionAmount: Double {
        calculation.commissionAmount
    }


    var netBankAmount: Double {
        calculation.netBankAmount
    }


    var grossProfitAmount: Double {
        calculation.grossProfitAmount
    }


    var profitAmount: Double {
        calculation.profitAmount
    }


    var calculation: POSCalculationResult {
        POSCalculator.calculate(
            fundingSources: fundingSources,
            posAmount: posAmount,
            commissionRate: currentRate
        )
    }


    // MARK: - KAYDET

    func saveTransaction() {

        if posBanks.isEmpty {
            return
        }

        if selectedBankIndex >=
            posBanks.count {

            return
        }

        let bank =
            posBanks[selectedBankIndex]

        var transaction =
            POSTransaction(
                companyID: company.id,
                posBankID: bank.id,
                customerName: customerName,
                principalAmount: principal,
                posAmount: posAmount,
                commissionRate: currentRate,
                commissionAmount: commissionAmount,
                netBankAmount: netBankAmount,
                grossProfitAmount: grossProfitAmount,
                profitAmount: profitAmount,
                fundingSources: fundingSources,
                installmentCount: installmentCount,
                status: .pending
            )

        if let old =
            editingTransaction {

            transaction.id =
                old.id

            transaction.transactionDate =
                old.transactionDate

            transaction.settlementDate =
                old.settlementDate

            transaction.status =
                old.status

            transaction.note =
                old.note
        }

        onSave(transaction)
    }


    // MARK: - PARA ÇEVİR

    func convertMoney(
        _ text: String
    ) -> Double {

        let clean =
            text.replacingOccurrences(
                of: ".",
                with: ""
            )

        return Double(clean) ?? 0
    }


    // MARK: - ORAN ÇEVİR

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


    // MARK: - SATIR

    func resultRow(
        title: String,
        value: Double
    ) -> some View {

        HStack {

            Text(title)

            Spacer()

            Text(
                money(value)
            )
        }
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

        formatter.maximumFractionDigits =
            2

        formatter.minimumFractionDigits =
            2

        let result =
            formatter.string(
                from: NSNumber(
                    value: value
                )
            ) ?? "0,00"

        return "₺" + result
    }


    static func initialMoney(
        _ value: Double?
    ) -> String {

        guard let value = value else {
            return ""
        }

        let formatter =
            NumberFormatter()

        formatter.numberStyle =
            .decimal

        formatter.groupingSeparator =
            "."

        formatter.maximumFractionDigits =
            0

        return formatter.string(
            from: NSNumber(
                value: value
            )
        ) ?? ""
    }
}
