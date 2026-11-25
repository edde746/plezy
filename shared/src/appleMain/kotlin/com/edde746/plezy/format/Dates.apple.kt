package com.edde746.plezy.format

import platform.Foundation.NSCalendar
import platform.Foundation.NSDateComponents
import platform.Foundation.NSDateFormatter
import platform.Foundation.NSDateFormatterLongStyle
import platform.Foundation.NSDateFormatterMediumStyle
import platform.Foundation.NSDateFormatterNoStyle
import platform.Foundation.NSLocale
import platform.Foundation.NSTimeZone
import platform.Foundation.timeZoneForSecondsFromGMT

internal actual fun localizedDate(year: Int, month: Int, day: Int, length: DateLength, locale: String): String? {
    val utc = NSTimeZone.timeZoneForSecondsFromGMT(0)
    val calendar = NSCalendar(calendarIdentifier = platform.Foundation.NSCalendarIdentifierGregorian) ?: return null
    calendar.timeZone = utc
    val components = NSDateComponents().apply {
        this.year = year.toLong()
        this.month = month.toLong()
        this.day = day.toLong()
    }
    if (!components.isValidDateInCalendar(calendar)) return null
    val date = calendar.dateFromComponents(components) ?: return null
    val formatter = NSDateFormatter()
    formatter.locale = NSLocale(localeIdentifier = locale)
    formatter.timeZone = utc
    formatter.dateStyle = if (length == DateLength.LONG) NSDateFormatterLongStyle else NSDateFormatterMediumStyle
    formatter.timeStyle = NSDateFormatterNoStyle
    return formatter.stringFromDate(date)
}

actual fun localToday(): com.edde746.plezy.model.CalendarDate {
    val calendar = NSCalendar.currentCalendar
    val parts = calendar.components(
        platform.Foundation.NSCalendarUnitYear or platform.Foundation.NSCalendarUnitMonth or platform.Foundation.NSCalendarUnitDay,
        fromDate = platform.Foundation.NSDate(),
    )
    return com.edde746.plezy.model.CalendarDate(parts.year.toInt(), parts.month.toInt(), parts.day.toInt())
}
