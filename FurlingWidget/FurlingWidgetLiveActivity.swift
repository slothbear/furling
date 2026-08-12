//
//  FurlingWidgetLiveActivity.swift
//  FurlingWidget
//
//  Created by adam on 8/12/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct FurlingWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct FurlingWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FurlingWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension FurlingWidgetAttributes {
    fileprivate static var preview: FurlingWidgetAttributes {
        FurlingWidgetAttributes(name: "World")
    }
}

extension FurlingWidgetAttributes.ContentState {
    fileprivate static var smiley: FurlingWidgetAttributes.ContentState {
        FurlingWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: FurlingWidgetAttributes.ContentState {
         FurlingWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: FurlingWidgetAttributes.preview) {
   FurlingWidgetLiveActivity()
} contentStates: {
    FurlingWidgetAttributes.ContentState.smiley
    FurlingWidgetAttributes.ContentState.starEyes
}
