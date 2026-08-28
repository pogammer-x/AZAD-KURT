import SwiftUI
import Foundation

struct AddReceivableView: View {

    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    @State private var debtorName = ""
    @State private var reason = ""
    @State private var amount = ""
    @State private var dailyInterestRate = ""

    @State private var dueDate = Date()
    @State private var hasDueDate = true

    @State private var compoundInterest = true
    @State private var note = ""
    @State private var selectedCompanyID: UUID?

    var body: some View {

        VStack(spacing: 0) {

            HStack {

                VStack(alignment: .leading, spacing: 4) {

                    Text("Yeni Alacak")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Yeni alacak kaydı oluştur")
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

                Section(header: Text("ALACAK BİLGİLERİ")) {

                    Picker("Şirket", selection: $selectedCompanyID) {
                        ForEach(store.companies) { company in
                            Text(company.name).tag(company.id as UUID?)
                        }
                    }

                    TextField(
                        "Borçlu / Kişi Adı",
                        text: $debtorName
                    )

                    TextField(
                        "Alacak Nedeni",
                        text: $reason
                    )
                    TextField(
                        "Ana Para Tutarı",
                        text: Binding(
                            get: {
                                amount
                            },
                            set: { newValue in
                                let digits = newValue.filter { $0.isNumber }

                                if let number = Int(digits) {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    formatter.groupingSeparator = "."
                                    formatter.maximumFractionDigits = 0

                                    amount = formatter.string(
                                        from: NSNumber(value: number)
                                    ) ?? digits
                                } else {
                                    amount = ""
                                }
                            }
                        )
                    )

                    }
                Section(header: Text("VADE VE FAİZ")) {

                    TextField(
                        "Günlük Oran (%)",
                        text: $dailyInterestRate
                    )

                    Toggle(
                        "Vade Tarihi Var",
                        isOn: $hasDueDate
                    )

                    if hasDueDate {

                        DatePicker(
                            "Vade Tarihi",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }

                    Toggle(
                        "Bileşik Faiz",
                        isOn: $compoundInterest
                    )
                }

                Section(header: Text("NOT")) {

                    TextField(
                        "Açıklama / Not",
                        text: $note
                    )
                }
            }

            Divider()

            HStack {

                Spacer()

                Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }

                Button("Alacağı Kaydet") {
                    saveReceivable()
                }
                .disabled(
                    debtorName.isEmpty ||
                    amountValue <= 0 ||
                    selectedCompanyID == nil
                )
            }
            .padding()
        }
        .frame(
            minWidth: 600,
            minHeight: 600
        )
        .onAppear {
            if selectedCompanyID == nil {
                selectedCompanyID = store.companies.first?.id
            }
        }
    }

    var amountValue: Double {

        let cleaned = amount
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")

        return Double(cleaned) ?? 0
    }

    var interestRateValue: Double {

        let cleaned = dailyInterestRate
            .replacingOccurrences(of: ",", with: ".")

        return Double(cleaned) ?? 0
    }

    func saveReceivable() {

        guard let selectedCompanyID else {
            return
        }

        let newReceivable = Receivable(
            companyID: selectedCompanyID,
            debtorName: debtorName,
            reason: reason,
            principalAmount: amountValue,
            dailyInterestRate: interestRateValue,
            startDate: Date(),
            dueDate: hasDueDate ? dueDate : nil,
            totalPaid: 0,
            isCompoundInterest: compoundInterest,
            status: .active,
            note: note,
            createdAt: Date(),
            updatedAt: Date()
        )

        store.receivables.append(newReceivable)

        presentationMode.wrappedValue.dismiss()
    }
}
