import SwiftUI

struct ContentView: View {

    @EnvironmentObject var store: AppStore
    @State private var selectedMenu: MenuItem = .dashboard

    enum MenuItem: String, CaseIterable, Identifiable {
        case dashboard = "Ana Panel"
        case companies = "Şirketler"
        case pos = "POS İşlemleri"
        case receivables = "Alacaklar"
        case payments = "Ödemeler"
        case incomeExpense = "Gelir / Gider"
        case invoices = "Faturalar"
        case reports = "Raporlar"
        case history = "Finansal Geçmiş"
        case settings = "Ayarlar"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .companies: return "building.2.fill"
            case .pos: return "creditcard.fill"
            case .receivables: return "arrow.down.circle.fill"
            case .payments: return "arrow.up.circle.fill"
            case .invoices: return "doc.text.fill"
            case .history: return "clock.arrow.circlepath"
            case .incomeExpense: return "chart.bar.fill"
            case .reports: return "doc.text.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {

            VStack(alignment: .leading, spacing: 8) {

                Text("AZADOĞLU")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("MANAGER")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textSecondary)

                Divider()
                    .padding(.vertical, 10)

                ForEach(MenuItem.allCases) { item in
                    Button {
                        selectedMenu = item
                    } label: {
                        HStack {
                            Image(systemName: item.icon)
                                .frame(width: 25)

                            Text(item.rawValue)

                            Spacer()
                        }
                        .padding(8)
                        .foregroundColor(
                            selectedMenu == item
                                ? AppTheme.primaryText
                                : AppTheme.secondaryText
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    selectedMenu == item
                                        ? AppTheme.accent
                                        : Color.clear
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding()
            .frame(width: 240)
            .background(AppTheme.sidebar)

            Rectangle().fill(AppTheme.border).frame(width: 1)

            Group {
                switch selectedMenu {

                case .companies:
                    CompaniesView()

                case .dashboard:
                    DashboardView()
                        .environmentObject(store)
                case .pos:
                    POSManagementView()
                case .receivables:
                    ReceivablesView()
                        .environmentObject(store)
                case .payments:
                    PaymentsView()
                        .environmentObject(store)
                case .invoices:
                    InvoicesView()
                        .environmentObject(store)
                case .history:
                    FinancialHistoryView()
                        .environmentObject(store)
                case .incomeExpense:
                    IncomeExpenseView()
                        .environmentObject(store)

                case .reports:
                    FinancialReportsView()
                        .environmentObject(store)

                case .settings:
                    SettingsView()
                        .environmentObject(store)
                }
            }
            .environmentObject(store)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background)
        }
        .frame(
            minWidth: 1100,
            minHeight: 700
        )
        .corporateScreen()
    }
}


// MARK: - GEÇİCİ TEMİZ SAYFA

struct SimplePage: View {

    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(spacing: 20) {

            Image(systemName: icon)
                .font(.system(size: 45))

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.title3)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
