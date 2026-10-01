//
//  CopticLiturgicalCalendar.swift
//  iAlhanNew
//
//  Identifies which Coptic Orthodox liturgical season/feast is currently being
//  observed, so the home screen can feature it automatically instead of always
//  defaulting to whichever season happens to sort first in the database.
//

import Foundation

/// Computes the currently observed Coptic Orthodox liturgical season for a given date.
///
/// Two kinds of season are modeled here, matching the 11 rows in the app's `season`
/// table (Advent, Nativity, Epiphany, Jonah, Great Lent, Palm Sunday, Pascha,
/// Apocalypse, Resurrection, Nairouz, Feast of the Cross):
///
/// - **Fixed feasts**, pinned to a specific day of the Coptic calendar (Nairouz, the
///   Feast of the Cross, Advent, Nativity, Epiphany). These are computed with
///   Foundation's built-in `Calendar(identifier: .coptic)`, which already knows the
///   Coptic leap-day (epagomenal day) rule, so no hand-rolled date arithmetic is needed
///   or risked here.
/// - **Movable feasts**, pinned relative to Pascha (Easter): Jonah's fast, Great Lent,
///   Holy Week (Palm Sunday), the Apocalypse (Holy Saturday) vigil, Pascha itself, and
///   the Resurrection season leading up to Pentecost. Pascha's date is computed with
///   the Meeus algorithm for the Julian-calendar Easter — the basis the whole Eastern
///   Orthodox communion (including the Coptic Orthodox Church) uses — then converted to
///   the Gregorian calendar with the standard Julian/Gregorian day offset for the
///   century in question.
///
/// Nairouz (1 Thout) runs through the eve of the Feast of the Cross; the Feast of the
/// Cross itself (17 Thout, the one that falls in September — not the separate, minor
/// March commemoration) is a 3-day feast (17-19 Thout); Epiphany/Theophany (11 Toubah)
/// is also a 3-day feast (11-13 Toubah). Advent, Nativity, and the Pascha-relative
/// ranges are the other well-established canonical spans. All of this is easy to adjust
/// in `fixedFeastWindows` / `movableFeastWindows` below if the app's own conventions
/// differ from what's encoded here.
@MainActor
enum CopticLiturgicalCalendar {

    /// A named season and the closed range of days (at day granularity) it covers.
    struct SeasonWindow {
        let title: String
        let range: ClosedRange<Date>
    }

    /// Returns the named season that actually contains `date`, or `nil` during
    /// annual/ordinary time between the modeled seasons.
    static func currentSeasonTitle(on date: Date = Date()) -> String? {
        let today = gregorian.startOfDay(for: date)
        return seasonWindows(around: today)
            .first(where: { $0.range.contains(today) })?
            .title
    }

    /// Returns the named season whose start date follows `date` most closely.
    static func upcomingSeasonTitle(on date: Date = Date()) -> String? {
        let today = gregorian.startOfDay(for: date)
        return seasonWindows(around: today)
            .filter { $0.range.lowerBound > today }
            .min { $0.range.lowerBound < $1.range.lowerBound }?
            .title
    }

    private static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.current
        return calendar
    }()
    private static let coptic: Calendar = {
        var calendar = Calendar(identifier: .coptic)
        calendar.timeZone = TimeZone.current
        return calendar
    }()

    private static func seasonWindows(around today: Date) -> [SeasonWindow] {
        fixedFeastWindows(around: today) + movableFeastWindows(around: today)
    }

    // MARK: Fixed feasts (Coptic calendar day-of-year)

    private static func fixedFeastWindows(around today: Date) -> [SeasonWindow] {
        // Computed for both the Coptic year containing `today` and the following one:
        // for most of the year the upcoming fixed feasts already fall in the current
        // Coptic year, but during the last few days of a Coptic year (the epagomenal
        // days in early September) the next Nairouz/Cross/Advent already belong to the
        // year that's about to start, and during the summer months the current Coptic
        // year's own fixed feasts are all in the past, so the *next* Coptic year's are
        // the ones actually upcoming.
        let copticYear = coptic.component(.year, from: today)
        return windowsForFixedFeasts(copticYear: copticYear)
            + windowsForFixedFeasts(copticYear: copticYear + 1)
    }

    private static func windowsForFixedFeasts(copticYear: Int) -> [SeasonWindow] {
        [
            // Nairouz (Coptic New Year, 1 Thout) runs through the eve of the Feast of
            // the Cross, 16 Thout.
            window("Nairouz", copticYear: copticYear, startMonth: 1, startDay: 1, endMonth: 1, endDay: 16),
            // Feast of the Cross (the September one, 17 Thout): a 3-day feast, 17-19 Thout.
            window("Feast of the Cross", copticYear: copticYear, startMonth: 1, startDay: 17, endMonth: 1, endDay: 19),
            // Advent (the Nativity Fast): 16 Hathor through the eve of Nativity, 28 Koiak.
            window("Advent", copticYear: copticYear, startMonth: 3, startDay: 16, endMonth: 4, endDay: 28),
            // Nativity (Christmastide): 29 Koiak (Coptic Christmas) through the eve of Epiphany, 10 Toubah.
            window("Nativity", copticYear: copticYear, startMonth: 4, startDay: 29, endMonth: 5, endDay: 10),
            // Epiphany (Theophany): a 3-day feast, 11-13 Toubah.
            window("Epiphany", copticYear: copticYear, startMonth: 5, startDay: 11, endMonth: 5, endDay: 13)
        ].compactMap { $0 }
    }

    private static func window(
        _ title: String,
        copticYear: Int,
        startMonth: Int,
        startDay: Int,
        endMonth: Int? = nil,
        endDay: Int? = nil
    ) -> SeasonWindow? {
        guard let start = copticDate(year: copticYear, month: startMonth, day: startDay) else { return nil }
        guard let end = endMonth.flatMap({ endMonth in
            endDay.flatMap { endDay in copticDate(year: copticYear, month: endMonth, day: endDay) }
        }) else {
            return SeasonWindow(title: title, range: start...start)
        }
        return SeasonWindow(title: title, range: start...end)
    }

    private static func copticDate(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents()
        components.calendar = coptic
        components.year = year
        components.month = month
        components.day = day
        return coptic.date(from: components)
    }

    // MARK: Movable feasts (relative to Pascha)

    private static func movableFeastWindows(around today: Date) -> [SeasonWindow] {
        let year = gregorian.component(.year, from: today)
        guard let pascha = orthodoxEaster(year: year) else { return [] }

        return [
            // 3-day fast beginning 2 weeks (14 days) before Great Lent starts.
            window("Jonah", from: -69, to: -67, relativeTo: pascha),
            // The "Holy 55 days": a week of preparation plus 40 days of Lent proper,
            // ending the eve of Palm Sunday.
            window("Great Lent", from: -55, to: -8, relativeTo: pascha),
            // Palm Sunday through Good Friday.
            window("Palm Sunday", from: -7, to: -2, relativeTo: pascha),
            // Holy Saturday: the vigil during which the entire Book of Revelation is read.
            window("Apocalypse", from: -1, to: -1, relativeTo: pascha),
            // Easter Sunday through Bright/Renewal Week.
            window("Pascha", from: 0, to: 6, relativeTo: pascha),
            // The remainder of the Great 50 Days, up to the eve of Pentecost.
            window("Resurrection", from: 7, to: 49, relativeTo: pascha)
        ].compactMap { $0 }
    }

    private static func window(_ title: String, from startOffset: Int, to endOffset: Int, relativeTo pascha: Date) -> SeasonWindow? {
        guard let start = gregorian.date(byAdding: .day, value: startOffset, to: pascha),
              let end = gregorian.date(byAdding: .day, value: endOffset, to: pascha) else { return nil }
        return SeasonWindow(title: title, range: start...end)
    }

    /// The Julian-calendar (Meeus) algorithm for Pascha, converted to the Gregorian
    /// calendar via the standard day offset between the two calendars for the given
    /// century (13 days for 1900–2099, 14 days from 2100, and so on).
    private static func orthodoxEaster(year: Int) -> Date? {
        let a = year % 4
        let b = year % 7
        let c = year % 19
        let d = (19 * c + 15) % 30
        let e = (2 * a + 4 * b - d + 34) % 7
        let month = (d + e + 114) / 31
        let day = ((d + e + 114) % 31) + 1
        let julianToGregorianOffset = year / 100 - year / 400 - 2

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let julianCalendarDate = gregorian.date(from: components) else { return nil }
        return gregorian.date(byAdding: .day, value: julianToGregorianOffset, to: julianCalendarDate)
    }
}
