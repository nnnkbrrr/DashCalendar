//
//  Date Extensions.swift
//  DashCalendar
//
//  Created by Nikita on 12/7/24.
//

import Foundation

extension Date {
    var weekdayName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self)
    }
    
    var shortWeekdayName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: self)
    }
    
    var shortMonthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "MMM"
        return dateFormatter.string(from: self)
    }
    
    var day: Int {
        Calendar.current.component(.day, from: self)
    }
    
    static var weekdayName: String {
        Date().weekdayName
    }
    
    static var shortWeekdayName: String {
        Date().shortWeekdayName
    }
    
    static var shortMonthName: String {
        Date().shortMonthName
    }
    
    static var day: Int {
        Date().day
    }
}
