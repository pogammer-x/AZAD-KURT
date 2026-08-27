import SwiftUI

struct DashboardView: View {

    @EnvironmentObject var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                Text("Ana Panel")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Tüm şirketlerin finansal durumunu tek ekrandan yönetin.")
                    .foregroundColor(.secondary)

                Divider()
               
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 220), spacing: 16)
                    ],
                    spacing: 16
                ) {
                    summaryCard(
                        title: "Toplam Net Bakiye",
                        amount: store.totalAllCompaniesNetBalance,
                        icon: "banknote.fill"
                    )

                    summaryCard(
                        title: "Alacaklar",
                        amount: store.receivablesTotal,
                        icon: "arrow.down.circle.fill"
                    )

                    summaryCard(
                        title: "Ödemeler",
                        amount: store.paymentsTotal,
                        icon: "arrow.up.circle.fill"
                    )

                    summaryCard(
                        title: "Gelir",
                        amount: store.totalIncome,
                        icon: "plus.circle.fill"
                    )

                    summaryCard(
                        title: "Gider",
                        amount: store.totalExpense,
                        icon: "minus.circle.fill"
                    )

                    summaryCard(
                        title: "Net Kâr",
                        amount: store.netProfit,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }

      

                Spacer()
            }
            .padding(28)
        }
    }

    private func summaryCard(
        title: String,
        amount: Double,
        icon: String
    ) -> some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack {
                Image(systemName: icon)

                Spacer()
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("₺\(amount, specifier: "%.2f")")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.primary.opacity(0.05))
        )
    }
}
