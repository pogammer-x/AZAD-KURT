import SwiftUI
import Foundation

struct PaymentsView: View {

    @EnvironmentObject var store: AppStore

    private var totalPayments: Double {
        store.payments.filter { !$0.isCancelled }.reduce(0) { total, payment in
            total + payment.amount
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("Ödemeler")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Yapılan tüm ödemeleri buradan takip edebilirsiniz.")
                .foregroundColor(.secondary)

            Divider()

            // TOPLAM ÖDEME
            VStack(alignment: .leading, spacing: 5) {
                Text("TOPLAM ÖDEME")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(currencyText(totalPayments))
                    .font(.title)
                    .fontWeight(.bold)
            }

            Divider()

            if store.payments.isEmpty {

                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "arrow.up.circle")
                        .font(.system(size: 40))

                    Text("Henüz ödeme bulunmuyor")
                        .font(.headline)

                    Text("Alacaklara yapılan ödemeler burada görünecek.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Spacer()

            } else {

                ScrollView {
                    VStack(spacing: 10) {

                        ForEach(store.payments) { payment in

                            HStack {

                                VStack(alignment: .leading, spacing: 5) {

                                    Text(payment.payerName)
                                        .font(.headline)
                                        .fontWeight(.semibold)

                                    Text(payment.reference + (payment.isCancelled ? " · İptal" : ""))
                                        .font(.caption)
                                        .foregroundColor(payment.isCancelled ? .red : .secondary)

                                    if !payment.note.isEmpty {
                                        Text(payment.note)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Text(dateText(payment.paymentDate))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text(currencyText(payment.amount))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .opacity(payment.isCancelled ? 0.5 : 1)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.card)
                            )
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(25)
        .background(AppTheme.background.edgesIgnoringSafeArea(.all))
        .corporateScreen()
    }

    private func currencyText(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")

        return formatter.string(
            from: NSNumber(value: amount)
        ) ?? "₺0,00"
    }

    private func dateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"

        return formatter.string(from: date)
    }
}
