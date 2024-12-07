//
//  ContentView.swift
//  DashCalendar
//
//  Created by Nikita on 11/1/24.
//

import SwiftUI
import EventKit

struct ContentView: View {
    let eventStore: EKEventStore = .init()
    let previewEntry: Provider.Entry = .init(date: Date(), startOfTheWeek: .monday)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                DashCalendarWidgetEntryView(entry: previewEntry)
                    .padding(16)
                    .background(Color.primary.colorInvert())
                    .cornerRadius(21)
                    .overlay {
                        RoundedRectangle(cornerRadius: 21)
                            .stroke(Color.gray, lineWidth: 0.25)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(2.139, contentMode: .fit)
                
                switch EKEventStore.authorizationStatus(for: .event) {
                    case .notDetermined: Button("Give access to events") {
                        eventStore.requestFullAccessToEvents { _, _ in }
                    }
                    case .denied: Text("Denied")
                    default: Text("Granted")
                }
            }
            .padding()
        }
        .background(Color.gray.opacity(0.2))
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
