//
//  DashCalendarWidget.swift
//  DashCalendarWidget
//
//  Created by Nikita on 11/1/24.
//

import SwiftUI
import WidgetKit
import EventKit

class DashCalendarAppearance {
    static let shared: DashCalendarAppearance = .init()
    
    let font: Font = .system(size: 10, weight: .semibold)
    
    private init() { }
}

class CalendarDay: Identifiable {
    let date: Date
    let number: Int
    
    let isPrevMonth: Bool
    let isNextMonth: Bool
    
    let isToday: Bool
    
    let events: [EKEvent]
    
    init(_ date: Date, events: [EKEvent], isPrevMonth: Bool = false, isNextMonth: Bool = false) {
        self.date = date
        self.number = date.day
        
        self.isPrevMonth = isPrevMonth
        self.isNextMonth = isNextMonth
        
        self.isToday = Calendar.current.isDateInToday(date)
        
        var filteredEvents: [EKEvent] = []
        for event in events {
            if event.startDate...event.endDate ~= date {
                filteredEvents.append(event)
            }
        }
        self.events = filteredEvents
    }
    
    var weekdayName: String {
        self.date.weekdayName
    }
    
    var isFaded: Bool {
        return isPrevMonth || isNextMonth
    }
}

public struct DashCalendarWidgetEntryView: View {
    var entry: Provider.Entry
    let days: [CalendarDay]
    let events: [EKEvent]
    
    init(entry: Provider.Entry) {
        self.entry = entry
        
        let firstMonthDay = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let range = calendar.range(of: .day, in: .month, for: firstMonthDay)!
        let lastMonthDay = calendar.date(byAdding: .day, value: range.count - 1, to: firstMonthDay)!
        let firstNextMonthDay = calendar.date(byAdding: .day, value: 1, to: lastMonthDay)!
        
        var events: [EKEvent] = []
        
        let authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
        
        if authorizationStatus == .fullAccess || authorizationStatus == .restricted {
            let predicate = eventStore.predicateForEvents(
                withStart: firstMonthDay,
                end: firstNextMonthDay,
                calendars: eventStore.calendars(for: .event).filter { !$0.isSubscribed }
            )
            
            events = eventStore.events(matching: predicate)
        }
        
        var days: [CalendarDay] = []
        
        // Previous month days
        let weekdayOffset = (calendar.component(.weekday, from: firstMonthDay) - entry.startOfTheWeek.rawValue + 7) % 7
        if weekdayOffset > 0 {
            for i in (1...weekdayOffset).reversed() {
                if let prevMonthDay: Date = calendar.date(byAdding: .day, value: -i, to: firstMonthDay) {
                    days.append(.init(prevMonthDay, events: events, isPrevMonth: true))
                }
            }
        }
        
        // Current month days
        let currentMonthDaysIndexes: Range<Int> = (0..<range.count)
        let currentMonthDates: [Date] = currentMonthDaysIndexes.compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: firstMonthDay)
        }
        let currentMonthDays: [CalendarDay] = currentMonthDates.map { CalendarDay($0, events: events) }
        days.append(contentsOf: currentMonthDays)
        
        // Next month days
        let remainingDays = (7 - days.count % 7) % 7
        if remainingDays > 0 {
            for i in 1...remainingDays {
                if let nextMonthDay: Date = calendar.date(byAdding: .day, value: i, to: lastMonthDay) {
                    days.append(.init(nextMonthDay, events: events, isNextMonth: true))
                }
            }
        }
        
        self.events = events
        self.days = days
    }
    
    // private variables
    
    private let appearance: DashCalendarAppearance = .shared
    private let eventStore: EKEventStore = .init()
    private let calendar = Calendar.current
    
    public var body: some View {
        HStack {
            TodayPreview(days: days)
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    let rowsCount: Int = days.count / 7
                    let rowHeight: CGFloat = geometry.size.height/(CGFloat(rowsCount) + 1.5)
                    let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 7)
                    
                    weekdayNames(rowHeight: rowHeight)
                    
                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(days) { day in
                            DayPreview(day: day, rowHeight: rowHeight)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
            }
        }
        .padding(-8)
    }
    
    @ViewBuilder func weekdayNames(rowHeight: CGFloat) -> some View {
        HStack {
            ForEach(days.prefix(7)) { day in
                Text(String(day.weekdayName.first ?? "-"))
                    .frame(maxWidth: .infinity)
            }
        }
        .font(appearance.font)
        .foregroundStyle(.gray)
        .frame(height: rowHeight)
        
        Divider()
            .frame(height: rowHeight/2)
    }
    
    struct DayPreview: View {
        private let appearance: DashCalendarAppearance = .shared
        let day: CalendarDay
        let rowHeight: CGFloat
        
        var body: some View {
            var foregroundColor: Color {
                if day.isToday { return .white }
                if let calendarColor: CGColor = day.events.first?.calendar.cgColor { return Color(cgColor: calendarColor) }
                return .primary
            }
            
            Text("\(day.number)")
                .font(appearance.font)
                .foregroundStyle(foregroundColor)
                .opacity(day.isFaded ? 0.25 : 1)
                .frame(height: rowHeight)
                .frame(maxWidth: .infinity)
                .background {
                    if day.isToday {
                        Circle()
                            .foregroundStyle(Color.red)
                    }
                }
        }
    }
    
    struct TodayPreview: View {
        private let appearance: DashCalendarAppearance = .shared
        let today: CalendarDay
        let event: EKEvent?
        
        init(days: [CalendarDay]) {
            self.today = days.first(where: { $0.isToday }) ?? .init(Date(), events: [])
            
            let eventStore: EKEventStore = .init()
            let authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
            
            let eventsPredicateStart: Date = Date()
            let eventsPredicateEnd = Calendar.current.date(byAdding: .day, value: 7, to: eventsPredicateStart)!
            
            if authorizationStatus == .fullAccess || authorizationStatus == .restricted {
                let predicate = eventStore.predicateForEvents(
                    withStart: eventsPredicateStart,
                    end: eventsPredicateEnd,
                    calendars: eventStore.calendars(for: .event).filter { !$0.isSubscribed }
                )
                
                if let firstEvent = eventStore.events(matching: predicate).first {
                    self.event = firstEvent
                } else {
                    self.event = nil
                }
            } else {
                self.event = nil
            }
        }
        
        var body: some View {
            VStack(spacing: 3) {
                if event != nil { Spacer() }
                    
                HStack(spacing: 5) {
                    Text(today.date.shortWeekdayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                    
                    Text(today.date.shortMonthName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                }
                
                if let event {
                    VStack(spacing: 0) {
                        Text("\(today.number)")
                            .font(.system(size: 60).weight(.semibold))
                            .minimumScaleFactor(0.01)
                        
                        Spacer()
                        
                        EventView(event: event)
                    }
                } else {
                    Text("\(today.number)")
                        .font(.system(size: 60, weight: .bold))
                }
            }
            .frame(width: 100)
        }
        
        struct EventView: View {
            private let appearance: DashCalendarAppearance = .shared
            let event: EKEvent
            let color: Color
            
            init(event: EKEvent) {
                self.event = event
                self.color = Color(event.calendar.cgColor)
            }
            
            var body: some View {
                VStack(spacing: 3) {
                    var dayName: String {
                        let startDate: Date = event.startDate
                        if Calendar.current.isDateInToday(startDate) { return "Today" }
                        else if Calendar.current.isDateInTomorrow(startDate) { return "Tomorrow" }
                        else { return "\(startDate.shortWeekdayName) \(startDate.day)" }
                    }
                    
                    Text("Next: \(dayName)")
                        .font(appearance.font)
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(event.title)
                        .font(appearance.font)
                        .foregroundStyle(color)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(3)
                        .background(color.opacity(0.2))
                        .cornerRadius(5)
                }
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let previewEntry: Provider.Entry = .init(date: Date(), startOfTheWeek: .monday)
    DashCalendarWidgetEntryView(entry: previewEntry)
        .frame(width: 338, height: 158)
        .padding(16)
        .background(Color.black)
        .cornerRadius(21)
}
