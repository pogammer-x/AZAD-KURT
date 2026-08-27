import SwiftUI
import Foundation

struct EditReceivableView: View {

    @EnvironmentObject var store: AppStore
    @Environment(\.presentationMode) var presentationMode

    let receivable: Receivable

    @State private var debtorName: String
    @State private var reason: String
    @State private var amount: String
    @State private var dailyInterestRate: String

    @State private var dueDate: Date
    @State private var hasDueDate: Bool

    @State private var compoundInterest: Bool
    @State private var note: String

    init(receivable: Receivable) {

        self.receivable = receivable

        _debtorName = State(
            initialValue: receivable.debtorName
        )

        _reason = State(
            initialValue: receivable.reason
        )

        _amount = State(
            initialValue: EditReceivableView.moneyInput(
                receivable.principalAmount
            )
        )

        _dailyInterestRate = State(
            initialValue: EditReceivableView.rateInput(
                receivable.dailyInterestRate
            )
        )

        _dueDate = State(
            initialValue:
                receivable.dueDate ?? Date()
        )

        _hasDueDate = State(
            initialValue:
                receivable.dueDate != nil
        )

        _compoundInterest = State(
            initialValue:
                receivable.isCompoundInterest
        )

        _note = State(
            initialValue:
                receivable.note
        )
    }


    var body: some View {

        VStack(spacing: 0) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text("Alacağı Düzenle")
                        .font(.title)
                        .fontWeight(.bold)

                    Text(receivable.debtorName)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Kapat") {
                    presentationMode
                        .wrappedValue
                        .dismiss()
                }
            }
            .padding()

            Divider()

            Form {

                Section(
                    header:
                        Text("ALACAK BİLGİLERİ")
                ) {

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
                        text: $amount
                    )
                }


                Section(
                    header:
                        Text("VADE VE FAİZ")
                ) {

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


                Section(
                    header:
                        Text("NOT")
                ) {

                    TextField(
                        "Açıklama / Not",
                        text: $note
                    )
                }
            }

            Divider()

            HStack {

                Button("İptal") {

                    presentationMode
                        .wrappedValue
                        .dismiss()
                }

                Spacer()

                Button("Değişiklikleri Kaydet") {

                    saveChanges()
                }
                .disabled(
                    debtorName
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty
                    ||
                    amountValue <= 0
                )
            }
            .padding()
        }
        .frame(
            minWidth: 600,
            minHeight: 600
        )
    }


    // MARK: - TUTAR

    var amountValue: Double {

        let cleaned =
            amount
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


    // MARK: - ORAN

    var rateValue: Double {

        let cleaned =
            dailyInterestRate
                .replacingOccurrences(
                    of: ",",
                    with: "."
                )

        return Double(cleaned) ?? 0
    }


    // MARK: - KAYDET

    func saveChanges() {

        guard let index =
            store.receivables.firstIndex(
                where: {
                    $0.id == receivable.id
                }
            )
        else {

            return
        }

        store.receivables[index].debtorName =
            debtorName.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        store.receivables[index].reason =
            reason

        store.receivables[index].principalAmount =
            amountValue

        store.receivables[index].dailyInterestRate =
            rateValue

        store.receivables[index].dueDate =
            hasDueDate
            ? dueDate
            : nil

        store.receivables[index].isCompoundInterest =
            compoundInterest

        store.receivables[index].note =
            note

        store.receivables[index].updatedAt =
            Date()

        presentationMode
            .wrappedValue
            .dismiss()
    }


    // MARK: - FORMAT

    static func moneyInput(
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

        return formatter.string(
            from:
                NSNumber(
                    value: value
                )
        ) ?? ""
    }


    static func rateInput(
        _ value: Double
    ) -> String {

        return String(
            format: "%.4f",
            value
        )
        .replacingOccurrences(
            of: ".",
            with: ","
        )
    }
}
