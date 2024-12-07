//
//  Entry.swift
//  DashCalendar
//
//  Created by Nikita on 12/7/24.
//

import WidgetKit

struct SimpleEntry: TimelineEntry {
    enum WeekStartDay: Int { case sunday = 1, monday = 2 }
    
    let date: Date
    let startOfTheWeek: WeekStartDay // Calendar.current.firstWeekday
}
