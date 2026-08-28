import SwiftUI

struct LoginView: View {

    let onLogin: (String, String) -> Void

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = true
    @State private var errorMessage: String = ""

    var body: some View {

        HStack(spacing: 0) {

            leftPanel

            loginPanel
        }
        .frame(
            minWidth: 1000,
            minHeight: 650
        )
        .background(
            AppTheme.background
        )
    }


    // MARK: - SOL PANEL

    var leftPanel: some View {

        ZStack {

            AppTheme.background

            Rectangle()
                .fill(AppTheme.accent)
                .frame(width: 6)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(
                alignment: .leading,
                spacing: 28
            ) {

                brandSection

                Spacer()

                mainTitleSection

                featureSection

                Spacer()

                footerSection
            }
            .padding(50)
        }
        .frame(
            minWidth: 540,
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }


    // MARK: - LOGO

    var brandSection: some View {

        HStack(spacing: 14) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 14
                )
                .fill(
                    Color.white.opacity(0.10)
                )
                .frame(
                    width: 52,
                    height: 52
                )

                Image(
                    systemName: "chart.bar.xaxis"
                )
                .font(
                    .system(
                        size: 24,
                        weight: .semibold
                    )
                )
                .foregroundColor(.white)
            }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text("AZADOĞLU")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundColor(.white)

                Text("MANAGER")
                    .font(
                        .system(
                            size: 11,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(
                        .white.opacity(0.55)
                    )
            }
        }
    }


    // MARK: - ANA BAŞLIK

    var mainTitleSection: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            Text(
                "Finansal kontrol,\ntek merkezde."
            )
            .font(
                .system(
                    size: 42,
                    weight: .bold
                )
            )
            .foregroundColor(.white)

            Text(
                "Şirketlerinizi, POS hareketlerinizi, alacaklarınızı ve kârlılığınızı profesyonel olarak yönetin."
            )
            .font(
                .system(
                    size: 16
                )
            )
            .foregroundColor(
                .white.opacity(0.68)
            )
            .frame(
                maxWidth: 430,
                alignment: .leading
            )
        }
    }


    // MARK: - ÖZELLİKLER

    var featureSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            featureRow(
                icon: "building.2",
                text: "Şirket ve POS yönetimi"
            )

            featureRow(
                icon: "creditcard",
                text: "1–18 taksit komisyon kontrolü"
            )

            featureRow(
                icon: "chart.line.uptrend.xyaxis",
                text: "Günlük, haftalık ve aylık kârlılık"
            )

            featureRow(
                icon: "person.2",
                text: "Yönetici ve personel işlem takibi"
            )
        }
    }


    func featureRow(
        icon: String,
        text: String
    ) -> some View {

        HStack(spacing: 12) {

            ZStack {

                Circle()
                    .fill(
                        Color.white.opacity(0.08)
                    )
                    .frame(
                        width: 34,
                        height: 34
                    )

                Image(
                    systemName: icon
                )
                .foregroundColor(
                    .white.opacity(0.85)
                )
            }

            Text(text)
                .foregroundColor(
                    .white.opacity(0.78)
                )
        }
    }


    // MARK: - ALT BİLGİ

    var footerSection: some View {

        HStack {

            Image(
                systemName: "lock.shield"
            )

            Text(
                "Güvenli Finansal Yönetim Platformu"
            )
        }
        .font(
            .system(size: 12)
        )
        .foregroundColor(
            .white.opacity(0.45)
        )
    }


    // MARK: - SAĞ PANEL

    var loginPanel: some View {

        ZStack {

            AppTheme.panel

            loginCard
        }
        .frame(
            minWidth: 460,
            maxWidth: 520,
            maxHeight: .infinity
        )
    }


    // MARK: - GİRİŞ KARTI

    var loginCard: some View {

        VStack(
            alignment: .leading,
            spacing: 24
        ) {

            loginHeader

            loginFields

            loginOptions

            errorSection

            loginButton

            Divider()
                .background(
                    Color.white.opacity(0.10)
                )

            securityInfo
        }
        .padding(42)
        .background(
            Color.white.opacity(0.055)
        )
        .cornerRadius(24)
        .padding(36)
    }


    // MARK: - GİRİŞ BAŞLIK

    var loginHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Hoş Geldiniz")
                .font(
                    .system(
                        size: 30,
                        weight: .bold
                    )
                )
                .foregroundColor(.white)

            Text(
                "Azadoğlu Manager hesabınıza giriş yapın."
            )
            .foregroundColor(
                .white.opacity(0.55)
            )
        }
    }


    // MARK: - ALANLAR

    var loginFields: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text("E-posta / Kullanıcı Adı")
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(
                        .white.opacity(0.70)
                    )

                TextField(
                    "ornek@azadoglu.com",
                    text: $email
                )
                .textFieldStyle(
                    RoundedBorderTextFieldStyle()
                )
            }

            VStack(
                alignment: .leading,
                spacing: 7
            ) {

                Text("Şifre")
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(
                        .white.opacity(0.70)
                    )

                SecureField(
                    "Şifrenizi girin",
                    text: $password
                )
                .textFieldStyle(
                    RoundedBorderTextFieldStyle()
                )
            }
        }
    }


    // MARK: - GİRİŞ SEÇENEKLERİ

    var loginOptions: some View {

        HStack {

            Toggle(
                "Beni hatırla",
                isOn: $rememberMe
            )
            .foregroundColor(
                .white.opacity(0.70)
            )

            Spacer()

            Button(
                "Şifremi Unuttum"
            ) {

                errorMessage =
                    "Şifre yenileme sistemi bulut hesabıyla birlikte aktif edilecek."
            }
            .buttonStyle(
                PlainButtonStyle()
            )
            .foregroundColor(
                .white.opacity(0.70)
            )
        }
        .font(
            .system(size: 12)
        )
    }


    // MARK: - HATA

    var errorSection: some View {

        Group {

            if !errorMessage.isEmpty {

                HStack(
                    alignment: .top,
                    spacing: 8
                ) {

                    Image(
                        systemName:
                            "exclamationmark.circle"
                    )

                    Text(
                        errorMessage
                    )
                }
                .font(
                    .system(size: 12)
                )
                .foregroundColor(
                    AppTheme.negative
                )
            }
        }
    }


    // MARK: - GİRİŞ BUTONU

    var loginButton: some View {

        Button(
            action: login
        ) {

            HStack {

                Spacer()

                Text("Giriş Yap")
                    .fontWeight(.semibold)

                Image(
                    systemName:
                        "arrow.right"
                )

                Spacer()
            }
            .padding(
                .vertical,
                13
            )
        }
        .buttonStyle(
            PlainButtonStyle()
        )
        .foregroundColor(
            AppTheme.primaryText
        )
        .background(
            AppTheme.accent
        )
        .cornerRadius(10)
    }


    // MARK: - GÜVENLİK

    var securityInfo: some View {

        HStack(
            spacing: 10
        ) {

            Image(
                systemName:
                    "checkmark.shield"
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(
                    "Kurumsal Oturum"
                )
                .fontWeight(.semibold)

                Text(
                    "Hesap yetkileri ve işlem geçmişi kullanıcı bazında tutulacaktır."
                )
                .font(
                    .system(size: 11)
                )
                .foregroundColor(
                    .white.opacity(0.45)
                )
            }
        }
        .foregroundColor(
            .white.opacity(0.70)
        )
    }


    // MARK: - GİRİŞ

    func login() {

        let cleanEmail =
            email.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if cleanEmail.isEmpty {

            errorMessage =
                "Kullanıcı adı veya e-posta girin."

            return
        }

        if password.isEmpty {

            errorMessage =
                "Şifrenizi girin."

            return
        }

        errorMessage = ""

        onLogin(
            cleanEmail,
            password
        )
    }
}
