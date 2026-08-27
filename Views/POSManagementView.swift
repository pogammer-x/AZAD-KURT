import SwiftUI

struct POSManagementView: View {
    @State private var showNewPOSTransaction = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {

            // ÜST BAŞLIK
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("POS İşlemleri")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Tüm POS hareketlerinizi tek ekrandan yönetin.")
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    showNewPOSTransaction = true
                } label: {
                    Label("Yeni POS İşlemi", systemImage: "plus")
                }
                .sheet(isPresented: $showNewPOSTransaction) {
                    NewPOSFormView(
                        isPresented: $showNewPOSTransaction
                    )
                }
            }

            Divider()

            // ÖZET KARTLARI
            HStack(spacing: 16) {
                summaryCard(
                    title: "Bekleyen POS",
                    amount: "₺0,00",
                    icon: "clock.fill"
                )

                summaryCard(
                    title: "Bugünkü POS",
                    amount: "₺0,00",
                    icon: "creditcard.fill"
                )

                summaryCard(
                    title: "Banka Kesintisi",
                    amount: "₺0,00",
                    icon: "percent"
                )

                summaryCard(
                    title: "Net Kasaya Geçecek",
                    amount: "₺0,00",
                    icon: "banknote.fill"
                )
            }

            Divider()

            // BOŞ DURUM
            VStack(spacing: 14) {
                Image(systemName: "creditcard")
                    .font(.system(size: 42))
                    .foregroundColor(.secondary)

                Text("Henüz POS işlemi bulunmuyor")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Yeni POS İşlemi butonundan ilk işleminizi oluşturabilirsiniz.")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(28)
    }

    private func summaryCard(
        title: String,
        amount: String,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)

                Spacer()
            }

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(amount)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}


// MARK: - YENİ POS İŞLEMİ

struct NewPOSFormView: View {

    @Binding var isPresented: Bool

    @State private var company = ""
    @State private var bank = ""
    @State private var customer = ""
    @State private var principalAmount = ""
    @State private var posAmount = ""
    @State private var commissionRate = ""
    @State private var installmentCount = "1"
    private var principalValue: Double {
        parseNumber(principalAmount)
    }
    private var posValue: Double {
        parseNumber(posAmount)
    }
    private var commissionValue: Double {
        parseNumber(commissionRate)
    }
    private var bankDeduction: Double {
        posValue * commissionValue / 100
    }
    private var netToCash: Double {
        posValue - bankDeduction
    }

    private func parseNumber(_ text: String) -> Double {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "₺", with: "")
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleaned) ?? 0
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")

        return formatter.string(from: NSNumber(value: value)) ?? "₺0,00"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {

            headerSection

            Divider()

            transactionInfoSection

            Divider()

            amountSection

            Divider()

            calculationSection

            Spacer()

            saveSection
        }
        .padding(30)
        .frame(minWidth: 650, minHeight: 600)
    }


    // MARK: Başlık

    private var headerSection: some View {
        HStack {
            Text("Yeni POS İşlemi")
                .font(.largeTitle)
                .fontWeight(.bold)

            Spacer()

            Button("Kapat") {
                isPresented = false
            }
        }
    }


    // MARK: İşlem Bilgileri

    private var transactionInfoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("İşlem Bilgileri")
                .font(.headline)

            fieldRow(
                title: "Şirket",
                placeholder: "Şirket seçilecek",
                text: $company
            )

            fieldRow(
                title: "POS Bankası",
                placeholder: "Banka seçilecek",
                text: $bank
            )

            fieldRow(
                title: "İşlem Yapılan Kişi",
                placeholder: "Ad Soyad",
                text: $customer
            )
        }
    }


    // MARK: Tutar ve Komisyon

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tutar ve Komisyon")
                .font(.headline)

            fieldRow(
                title: "Ana Tutar",
                placeholder: "₺0,00",
                text: $principalAmount
            )

            fieldRow(
                title: "POS Çekim Tutarı",
                placeholder: "₺0,00",
                text: $posAmount
            )

            fieldRow(
                title: "Komisyon Oranı",
                placeholder: "%0,00",
                text: $commissionRate
            )

            fieldRow(
                title: "Taksit Sayısı",
                placeholder: "1",
                text: $installmentCount
            )
        }
    }


    // MARK: Hesaplama Özeti

    private var calculationSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Banka Kesintisi")
                    .foregroundColor(.secondary)

                Text(currency(bankDeduction))
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("Net Kasaya Geçecek")
                    .foregroundColor(.secondary)

                Text(currency(netToCash))
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }

    // MARK: Kaydet

    private var saveSection: some View {
        HStack {
            Spacer()

            Button("İşlemi Kaydet") {
                // Sonraki aşamada kayıt işlemini bağlayacağız.
            }
            .keyboardShortcut(.defaultAction)
        }
    }


    // MARK: Form Satırı

    private func fieldRow(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack {
            Text(title)
                .frame(width: 150, alignment: .leading)

            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

