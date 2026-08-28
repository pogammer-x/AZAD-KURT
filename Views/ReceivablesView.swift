import SwiftUI
import Foundation

struct ReceivablesView: View {

    @EnvironmentObject var store: AppStore
    @State private var showAddReceivable = false
    @State private var editingReceivable: Receivable? = nil
    @State private var deletingReceivable: Receivable? = nil
    @State private var paymentReceivable: Receivable? = nil
    var body: some View {

        VStack(alignment: .leading, spacing: 20) {

            HStack {

                VStack(alignment: .leading, spacing: 4) {
                    
                   Text("Alacaklar")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Tüm alacaklarınızı buradan yönetin")
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("+ Yeni Alacak") {
                    showAddReceivable = true
                }
            }

            Divider()

            HStack(spacing: 15) {

                summaryCard(
                    title: "Toplam Alacak",
                    value: totalReceivables
                )

                summaryCard(
                    title: "Aktif Alacak",
                    value: activeReceivables
                )

                summaryCard(
                    title: "Tahsil Edilen",
                    value: totalPaid
                )
            }

            Divider()

            if store.receivables.isEmpty {

                Spacer()

                VStack(spacing: 12) {

                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)

                    Text("Henüz alacak kaydı yok")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Yeni Alacak butonundan ilk kaydınızı oluşturabilirsiniz.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Spacer()

            } else {

                ScrollView {
                    LazyVStack(spacing: 12) {
                    ForEach(store.receivables) { receivable in
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(receivable.debtorName)
                                    .fontWeight(.semibold)
                                Text(receivable.reason)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(receivable.reference)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(store.company(for: receivable.companyID)?.name ?? "Bilinmeyen Şirket")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 5) {
                                Text(
                                    currencyText(
                                        InterestCalculator.receivableCurrentAmount(
                                            receivable,
                                            payments: store.payments
                                        )
                                    )
                                )
                                .fontWeight(.bold)

                                Text("Ödenen: " + currencyText(receivable.totalPaid))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            VStack(spacing: 6) {
                                Button("Düzenle") { editingReceivable = receivable }
                                Button("Ödeme Ekle") { paymentReceivable = receivable }
                                    .disabled(receivable.status == .cancelled)
                                Button("İptal Et") { deletingReceivable = receivable }
                                    .disabled(receivable.status == .cancelled)
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(AppTheme.card))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.border))
                    }
                    }
                }
            }
        }
        .padding(25)
        .background(AppTheme.background.edgesIgnoringSafeArea(.all))
        .corporateScreen()
        .sheet(isPresented: $showAddReceivable) {

            AddReceivableView()
                .environmentObject(store)
        }
        .sheet(item: $editingReceivable) { receivable in
            EditReceivableView(receivable: receivable)
                .environmentObject(store)
        }
        .sheet(item: $paymentReceivable) { receivable in
            AddReceivablePaymentView(receivable: receivable)
                .environmentObject(store)
        }
        .alert(item: $deletingReceivable) { receivable in
            Alert(
                title: Text("Alacağı İptal Et"),
                message: Text("\(receivable.debtorName) kaydını iptal etmek istiyor musunuz?"),
                primaryButton: .destructive(Text("İptal Et")) {
                    if let index = store.receivables.firstIndex(
                        where: { $0.id == receivable.id }
                    ) {
                        store.receivables[index].status = .cancelled
                        store.receivables[index].updatedAt = Date()
                    }
                },
                secondaryButton: .cancel(Text("Vazgeç"))
            )
        }    }

    var totalReceivables: Double {

        store.receivables.reduce(0) {
            $0 + InterestCalculator.receivableCurrentAmount(
                $1,
                payments: store.payments
            )
        }
    }
    var activeReceivables: Double {

        store.receivables
            .filter {
                $0.status == .active
            }
            .reduce(0) {
                $0 + InterestCalculator.receivableCurrentAmount(
                    $1,
                    payments: store.payments
                )
            }
    }
    var totalPaid: Double {

        store.receivables.reduce(0) {
            $0 + $1.totalPaid
        }
    }

    func summaryCard(
        title: String,
        value: Double
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(currencyText(value))
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.cardElevated)
        )
    }

    func currencyText(_ value: Double) -> String {

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")

        return formatter.string(
            from: NSNumber(value: value)
        ) ?? "₺0,00"
    }
}
