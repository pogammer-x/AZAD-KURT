import SwiftUI

struct CompaniesView: View {

    @EnvironmentObject var store: AppStore

    @State private var showAddCompany = false
    @State private var newCompanyName = ""

    @State private var editingCompany: Company? = nil
    @State private var editingCompanyName = ""

    @State private var deletingCompany: Company? = nil

    var body: some View {
        NavigationView {
            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                headerSection

                if store.companies.isEmpty {

                    emptySection

                } else {

                    companyList
                }

                Spacer()
            }
            .padding(25)
        }
        .background(AppTheme.background.edgesIgnoringSafeArea(.all))
        .corporateScreen()

        // YENİ ŞİRKET
        .sheet(
            isPresented: $showAddCompany
        ) {

            addCompanyView
        }

        // ŞİRKET DÜZENLE
        .sheet(
            item: $editingCompany
        ) { company in

            editCompanyView(
                company
            )
        }

        // ŞİRKET SİL
        .alert(
            item: $deletingCompany
        ) { company in

            Alert(
                title: Text(
                    "Şirketi Sil"
                ),

                message: Text(
                    "\(company.name) şirketini silmek istediğinize emin misiniz? Bu şirkete bağlı POS bankaları ve POS işlemleri de silinir."
                ),

                primaryButton:
                    .destructive(
                        Text("Sil")
                    ) {

                        store.deleteCompany(
                            company
                        )

                        deletingCompany =
                            nil
                    },

                secondaryButton:
                    .cancel(
                        Text("Vazgeç")
                    )
            )
        }
    }

    // MARK: - BAŞLIK

    var headerSection: some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text("Şirketler")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(
                    "Şirketlerinizi ve POS bankalarınızı yönetin"
                )
                .foregroundColor(
                    AppTheme.textSecondary
                )
            }

            Spacer()

            Button(
                action: {

                    newCompanyName = ""
                    showAddCompany = true
                }
            ) {

                HStack {

                    Image(
                        systemName: "plus"
                    )

                    Text("Şirket Ekle")
                }
                .accentButton()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }


    // MARK: - BOŞ EKRAN

    var emptySection: some View {

        VStack(
            spacing: 15
        ) {

            Spacer()

            Image(
                systemName:
                    "building.2"
            )
            .font(
                .system(size: 50)
            )
            .foregroundColor(
                .secondary
            )

            Text(
                "Henüz şirket eklenmedi"
            )
            .font(.title2)
            .fontWeight(.semibold)

            Text(
                "İlk şirketinizi ekleyerek başlayın."
            )
            .foregroundColor(
                .secondary
            )

            Button(
                "Şirket Ekle"
            ) {

                newCompanyName = ""
                showAddCompany = true
            }

            Spacer()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }


    // MARK: - ŞİRKET LİSTESİ

    var companyList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {

                ForEach(store.companies) { company in

                    HStack(alignment: .center, spacing: 14) {

                        NavigationLink(
                            destination:
                                CompanyDetailView(company: company)
                                    .environmentObject(store)
                        ) {
                            HStack(spacing: 18) {

                                Text(String(company.name.prefix(1)).uppercased())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .frame(width: 52, height: 52)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(AppTheme.accent)
                                    )

                                VStack(alignment: .leading, spacing: 5) {

                                    Text(company.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .lineLimit(1)

                                    Text("\(store.posBanks.filter { $0.companyID == company.id }.count) POS bankası · Aktif finans hesabı")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("TOPLAM BAKİYE")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textSecondary)
                                    Text("₺\(company.balance, specifier: "%.2f")")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.accent)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                            .contentShape(Rectangle())
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AppTheme.cardSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        AppTheme.border,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        VStack(spacing: 8) {
                            Button("Düzenle") {
                                editingCompanyName = company.name
                                editingCompany = company
                            }
                            .buttonStyle(.borderless)

                            Button("Sil") {
                                deletingCompany = company
                            }
                            .buttonStyle(.borderless)
                        }
                        .frame(width: 72)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - ŞİRKET DÜZENLEME

    func editCompanyView(
        _ company: Company
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            Text(
                "Şirketi Düzenle"
            )
            .font(.title)
            .fontWeight(.bold)

            TextField(
                "Şirket adı",
                text:
                    $editingCompanyName
            )
            .textFieldStyle(
                RoundedBorderTextFieldStyle()
            )

            HStack {

                Button(
                    "İptal"
                ) {

                    editingCompany =
                        nil
                }

                Spacer()

                Button(
                    "Kaydet"
                ) {

                    updateCompany(
                        company
                    )
                }
                .disabled(
                    cleanEditingName
                        .isEmpty
                )
            }
        }
        .padding(30)
        .frame(
            width: 430,
            height: 220
        )
    }

    var addCompanyView: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("Yeni Şirket")
                .font(.title2)
                .fontWeight(.bold)

            TextField(
                "Şirket adı",
                text: $newCompanyName
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())

            HStack {
                Spacer()

                Button("Vazgeç") {
                    newCompanyName = ""
                    showAddCompany = false
                }

                Button("Şirket Ekle") {
                    addCompany()
                    showAddCompany = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(
            width: 430,
            height: 220
        )
    }
    // MARK: - ŞİRKET EKLE

    func addCompany() {

        let name =
            cleanNewCompanyName

        if name.isEmpty {
            return
        }

        let company =
            Company(
                name: name
            )

        store.addCompany(
            company
        )

        newCompanyName = ""

        showAddCompany = false
    }


    // MARK: - ŞİRKET GÜNCELLE

    func updateCompany(
        _ company: Company
    ) {

        let name =
            cleanEditingName

        if name.isEmpty {
            return
        }

        var updated =
            company

        updated.name =
            name

        store.updateCompany(
            updated
        )

        editingCompany =
            nil
    }


    // MARK: - TEMİZ İSİMLER

    var cleanNewCompanyName:
        String {

        return newCompanyName
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }


    var cleanEditingName:
        String {

        return editingCompanyName
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }
}
