import SwiftUI

struct EditPOSBankView: View {

    let bank: POSBank
    let onSave: (POSBank) -> Void
    let onCancel: () -> Void

    @State private var bankName: String
    @State private var singlePaymentRate: String
    @State private var installmentRates: [Int: String]
    @State private var isActive: Bool

    init(
        bank: POSBank,
        onSave: @escaping (POSBank) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.bank = bank
        self.onSave = onSave
        self.onCancel = onCancel

        _bankName = State(initialValue: bank.bankName)
        _singlePaymentRate = State(
            initialValue: String(format: "%.2f", bank.singlePaymentRate)
        )

        var rates: [Int: String] = [:]

        for installment in 2...18 {
            let value = bank.installmentRates[installment] ?? 0

            rates[installment] = String(
                format: "%.2f",
                value
            )
        }

        _installmentRates = State(initialValue: rates)
        _isActive = State(initialValue: bank.isActive)
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                HStack {
                    Text("POS Bankası Düzenle")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()

                    Button("Kapat") {
                        onCancel()
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Banka Adı")
                        .font(.headline)

                    TextField(
                        "Banka adı",
                        text: $bankName
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tek Çekim Banka Komisyon Oranı")
                        .font(.headline)

                    TextField(
                        "%0,00",
                        text: $singlePaymentRate
                    )
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                Toggle(
                    "POS Aktif",
                    isOn: $isActive
                )

                Divider()

                Text("Taksit Banka Komisyon Oranları")
                    .font(.title2)
                    .fontWeight(.bold)

                LazyVGrid(
                    columns: [
                        GridItem(
                            .adaptive(minimum: 180),
                            spacing: 12
                        )
                    ],
                    spacing: 12
                ) {
                    ForEach(2...18, id: \.self) { installment in
                        HStack {
                            Text("\(installment) Taksit")
                                .frame(
                                    width: 70,
                                    alignment: .leading
                                )

                            TextField(
                                "%0,00",
                                text: Binding(
                                    get: {
                                        installmentRates[installment] ?? ""
                                    },
                                    set: {
                                        installmentRates[installment] = $0
                                    }
                                )
                            )
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }

                Divider()

                HStack {
                    Spacer()

                    Button("İptal") {
                        onCancel()
                    }

                    Button("Kaydet") {
                        saveBank()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(30)
        }
        .frame(
            minWidth: 700,
            minHeight: 650
        )
    }

    private func saveBank() {

        var updatedBank = bank

        updatedBank.bankName = bankName
        updatedBank.singlePaymentRate =
            doubleValue(singlePaymentRate)

        var newRates: [Int: Double] = [:]

        for installment in 2...18 {
            newRates[installment] =
                doubleValue(
                    installmentRates[installment] ?? ""
                )
        }

        updatedBank.installmentRates = newRates
        updatedBank.isActive = isActive

        onSave(updatedBank)
    }

    private func doubleValue(
        _ text: String
    ) -> Double {

        let cleaned = text
            .replacingOccurrences(
                of: ",",
                with: "."
            )
            .replacingOccurrences(
                of: "%",
                with: ""
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        return Double(cleaned) ?? 0
    }
}
