import SwiftUI
import Foundation

struct AddReceivablePaymentView: View {

    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    let receivable: Receivable

    @State private var paymentAmount = ""
    @State private var note = ""

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
    }

    var currentAmount: Double {

        InterestCalculator.receivableCurrentAmount(
            receivable
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

        guard let index =
            store.receivables.firstIndex(
                where: {
                    $0.id == receivable.id
                }
            )
        else {
            return
        }

        store.receivables[index].totalPaid +=
            paymentValue

        store.receivables[index].updatedAt =
            Date()
        let newPayment = Payment(
            companyID: receivable.companyID,
            receivableID: receivable.id,
            payerName: receivable.debtorName,
            amount: paymentValue,
            paymentDate: Date(),
            paymentMethod: .cash,
            createdBy: "Kullanıcı",
            note: note
        )

        store.payments.append(newPayment)
        if InterestCalculator
            .receivableCurrentAmount(
                store.receivables[index]
            ) <= 0 {

            store.receivables[index].status =
                .paid
        }

        presentationMode.wrappedValue.dismiss()
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
