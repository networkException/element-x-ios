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

import Foundation

enum TemplatePromptType {
    case regular
    case upgrade
}

extension TemplatePromptType: Identifiable, CaseIterable {
    var id: Self { self }
    
    var title: String {
        switch self {
        case .regular:
            return "Make this chat public?"
        case .upgrade:
            return "Privacy warning"
        }
    }
    
    var imageSystemName: String {
        switch self {
        case .regular:
            return "app.gift"
        case .upgrade:
            return "shield"
        }
    }
}

enum TemplateViewModelAction {
    case accept
    case cancel
}

struct TemplateViewState: BindableState {
    var promptType: TemplatePromptType
    var count: Int
}

enum TemplateViewAction {
    case incrementCount
    case decrementCount
    case accept
    case cancel
}
