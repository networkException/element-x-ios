//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct EncryptedRoomTimelineView: View {
    @State private var showEncryptionInfo = false
    
    let timelineItem: EncryptedRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            Button {
                showEncryptionInfo = !showEncryptionInfo
            } label: {
                HStack(alignment: .top) {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.red)
                        .padding(.top, 1.0)
                    if showEncryptionInfo {
                        FormattedBodyText(text: encryptionDetails)
                    } else {
                        FormattedBodyText(text: timelineItem.text)
                    }
                }
                .animation(nil, value: showEncryptionInfo)
            }
        }
        .id(timelineItem.id)
    }
    
    private var encryptionDetails: String {
        switch timelineItem.encryptionType {
        case .unknown:
            return "Unknown"
        case .megolmV1AesSha2(let sessionId):
            return "Megolm session id: \(sessionId)"
        case .olmV1Curve25519AesSha2(let senderKey):
            return "Olm sender key: \(senderKey)"
        }
    }
}

struct EncryptedRoomTimelineView_Previews: PreviewProvider {
    static var previews: some View {
        body
        body.timelineStyle(.plain)
    }
    
    static var body: some View {
        VStack(alignment: .leading, spacing: 20.0) {
            EncryptedRoomTimelineView(timelineItem: itemWith(text: "Text",
                                                             timestamp: "Now",
                                                             isOutgoing: false,
                                                             senderId: "Bob"))
            
            EncryptedRoomTimelineView(timelineItem: itemWith(text: "Some other text",
                                                             timestamp: "Later",
                                                             isOutgoing: true,
                                                             senderId: "Anne"))
        }
    }
    
    private static func itemWith(text: String, timestamp: String, isOutgoing: Bool, senderId: String) -> EncryptedRoomTimelineItem {
        EncryptedRoomTimelineItem(id: UUID().uuidString,
                                  text: text,
                                  encryptionType: .unknown,
                                  timestamp: timestamp,
                                  inGroupState: .single,
                                  isOutgoing: isOutgoing,
                                  isEditable: false,
                                  senderId: senderId)
    }
}
