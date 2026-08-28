import Foundation

struct InterestCalculator {

    // MARK: - Gün sayısı

    static func numberOfDays(
        from startDate: Date,
        to endDate: Date
    ) -> Int {

        let calendar = Calendar.current

        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)

        let components = calendar.dateComponents(
            [.day],
            from: start,
            to: end
        )

        return max(components.day ?? 0, 0)
    }


    // MARK: - Bileşik faiz

    static func compoundAmount(
        principal: Double,
        dailyRate: Double,
        days: Int
    ) -> Double {

        guard principal > 0 else {
            return 0
        }

        guard dailyRate > 0 else {
            return principal
        }

        guard days > 0 else {
            return principal
        }

        let rate = dailyRate / 100

        return principal * pow(
            1 + rate,
            Double(days)
        )
    }


    // MARK: - Basit faiz

    static func simpleAmount(
        principal: Double,
        dailyRate: Double,
        days: Int
    ) -> Double {

        guard principal > 0 else {
            return 0
        }

        guard dailyRate > 0 else {
            return principal
        }

        guard days > 0 else {
            return principal
        }

        let rate = dailyRate / 100

        return principal +
        (
            principal *
            rate *
            Double(days)
        )
    }


    // MARK: - Standart güncel tutar

    static func currentAmount(
        principal: Double,
        dailyRate: Double,
        startDate: Date
    ) -> Double {

        let days = numberOfDays(
            from: startDate,
            to: Date()
        )

        return compoundAmount(
            principal: principal,
            dailyRate: dailyRate,
            days: days
        )
    }


    // MARK: - Kazanılan faiz

    static func interestEarned(
        principal: Double,
        dailyRate: Double,
        startDate: Date
    ) -> Double {

        let total = currentAmount(
            principal: principal,
            dailyRate: dailyRate,
            startDate: startDate
        )

        return max(
            total - principal,
            0
        )
    }


    // MARK: - ALACAK GÜNCEL BAKİYE
    // Ödemeleri tarih sırasına göre hesaba katar

    static func receivableCurrentAmount(
        _ receivable: Receivable,
        payments: [Payment] = []
    ) -> Double {

        let today = Date()

        let interestStartDate =
            receivable.dueDate ??
            receivable.startDate

        var balance =
            receivable.principalAmount

        var calculationDate =
            interestStartDate

        let receivablePayments = payments
            .filter {
                $0.receivableID == receivable.id && !$0.isCancelled
            }
            .sorted {
                $0.paymentDate < $1.paymentDate
            }


        // Ödeme kayıt sistemine geçmeden önce yapılmış eski tahsilatlar
        let registeredPaymentTotal =
            receivablePayments.reduce(0) {
                $0 + $1.amount
            }

        let oldUnregisteredPayments = max(
            receivable.totalPaid -
            registeredPaymentTotal,
            0
        )

        balance = max(
            balance - oldUnregisteredPayments,
            0
        )


        // Ödemeleri tek tek işle
        for payment in receivablePayments {

            if balance <= 0 {
                return 0
            }

            let effectivePaymentDate = min(
                payment.paymentDate,
                today
            )

            // Faiz başlangıcından önce ödeme varsa direkt düş
            if effectivePaymentDate <= calculationDate {

                balance = max(
                    balance - payment.amount,
                    0
                )

                continue
            }

            // Son hesap tarihinden ödeme tarihine kadar faiz
            let days = numberOfDays(
                from: calculationDate,
                to: effectivePaymentDate
            )

            if receivable.isCompoundInterest {

                balance = compoundAmount(
                    principal: balance,
                    dailyRate:
                        receivable.dailyInterestRate,
                    days: days
                )

            } else {

                balance = simpleAmount(
                    principal: balance,
                    dailyRate:
                        receivable.dailyInterestRate,
                    days: days
                )
            }

            // Sonra ödeme düş
            balance = max(
                balance - payment.amount,
                0
            )

            calculationDate =
                effectivePaymentDate
        }


        // Son ödemeden bugüne kadar faiz
        if balance > 0 {

            let remainingDays = numberOfDays(
                from: calculationDate,
                to: today
            )

            if receivable.isCompoundInterest {

                balance = compoundAmount(
                    principal: balance,
                    dailyRate:
                        receivable.dailyInterestRate,
                    days: remainingDays
                )

            } else {

                balance = simpleAmount(
                    principal: balance,
                    dailyRate:
                        receivable.dailyInterestRate,
                    days: remainingDays
                )
            }
        }

        return MoneyMath.rounded(max(balance, 0))
    }
}
