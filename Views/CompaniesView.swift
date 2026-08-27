import SwiftUI

struct CompaniesView: View {

    @EnvironmentObject var store: AppStore

    @State private var showAddCompany = false
    @State private var newCompanyName = ""

    @State private var editingCompany: Company? = nil
    @State private var editingCompanyName = ""

    @State private var deletingCompany: Company? = nil

    var body: some View {

        
            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                headerSection

                Divider()

                if store.companies.isEmpty {

                    emptySection

                } else {

                    companyList
                }

                Spacer()
            }
            .padding(25)
            

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
                    .secondary
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
            }
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {

                ForEach(store.companies) { company in

                    VStack(alignment: .leading, spacing: 10) {

                        NavigationLink(
                            destination:
                                CompanyDetailView(company: company)
                                    .environmentObject(store)
                        ) {
                            VStack(alignment: .leading, spacing: 14) {

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {

                                        Text(company.name)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .lineLimit(1)

                                        Text(
                                            "\(store.posBanks.filter { $0.companyID == company.id }.count) POS bankası"
                                        )
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }

                                Divider()

                                HStack(spacing: 24) {

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Toplam POS")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Text(
                                            "₺\(store.totalPOSAmount(for: company.id), specifier: "%.2f")"
                                        )
                                        .font(.headline)
                                    }

                                    Spacer()

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Net Bakiye")
                                            .font(.caption)
                                            .foregroundColor(.secondary)

                                        Text(
                                            "₺\(store.netBalance(for: company.id), specifier: "%.2f")"
                                        )
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    }
                                }
                            }
                            .padding(18)
                            .frame(width: 280, height: 145, alignment: .topLeading)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.primary.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        Color.primary.opacity(0.10),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)

                        HStack {
                            Spacer()

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
                        .frame(width: 280)
                    }
                }
            }
            .padding(.horizontal, 4)
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
            .textFieldStyle(.roundedBorder)

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
