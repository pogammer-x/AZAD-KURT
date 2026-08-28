import SwiftUI
import Foundation

struct AddReceivablePaymentView: View {

    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    let receivable: Receivable

    @State private var paymentAmount = ""
    @State private var note = ""
    @State private var paymentID = UUID()
    @State private var errorMessage: String?

    var body: some View {

        VStack(spacing: 0) {

            HStack {

                VStack(alignment: .leading, spacing: 4) {

                    Text("Ödeme Ekle")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(receivable.debtorName)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Kapat") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .padding()

            Divider()

            Form {

                Section(header: Text("ALACAK")) {

                    HStack {

                        Text("Güncel Kalan")

                        Spacer()

                        Text(currencyText(currentAmount))
                            .fontWeight(.bold)
                    }
                }

                Section(header: Text("ÖDEME")) {

                    TextField(
                        "Ödeme Tutarı",
                        text: Binding(
                            get: {
                                paymentAmount
                            },
                            set: { newValue in
                                let digits = newValue.filter { $0.isNumber }

                                if let number = Int(digits) {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    formatter.groupingSeparator = "."
                                    formatter.decimalSeparator = ","
                                    formatter.maximumFractionDigits = 0

                                    paymentAmount = formatter.string(from: NSNumber(value: number)) ?? ""
                                } else {
                                    paymentAmount = ""
                                }
                            }
                        )
                    )
                    TextField(
                        "Not",
                        text: $note
                    )
                }
            }

            Divider()

            HStack {

                Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }

                Spacer()

                Button("Ödemeyi Kaydet") {
                    savePayment()
                }
                .disabled(
                    paymentValue <= 0 ||
                    paymentValue > currentAmount
                )
            }
            .padding()
        }
        .frame(
            minWidth: 500,
            minHeight: 400
        )
        .alert(isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Alert(
                title: Text("Tahsilat Kaydedilemedi"),
                message: Text(errorMessage ?? "Bilinmeyen hata")
            )
        }
    }

    var currentAmount: Double {

        InterestCalculator.receivableCurrentAmount(
            receivable,
            payments: store.payments
        )
    }

    var paymentValue: Double {

        let cleaned = paymentAmount
            .replacingOccurrences(
                of: ".",
                with: ""
            )
            .replacingOccurrences(
                of: ",",
                with: "."
            )

        return Double(cleaned) ?? 0
    }

    func savePayment() {
        let newPayment = Payment(
            id: paymentID,
            companyID: receivable.companyID,
            receivableID: receivable.id,
            payerName: receivable.debtorName,
            amount: paymentValue,
            paymentDate: Date(),
            paymentMethod: .cash,
            createdBy: "Kullanıcı",
            note: note
        )
        switch store.recordReceivablePayment(newPayment) {
        case .success:
            presentationMode.wrappedValue.dismiss()
        case .failure(let message):
            errorMessage = message
        }
    }

    func currencyText(
        _ value: Double
    ) -> String {

        let formatter = NumberFormatter()

        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(
            identifier: "tr_TR"
        )

        return formatter.string(
            from: NSNumber(value: value)
        ) ?? "₺0,00"
    }
}
