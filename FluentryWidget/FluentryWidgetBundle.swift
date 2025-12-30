//
//  FluentryWidgetBundle.swift
//  FluentryWidget
//
//  Created by Rishith Chennupati on 11/9/25.
//

import WidgetKit
import SwiftUI

@main
struct FluentryWidgetBundle: WidgetBundle {
    var body: some Widget {
        FluentryStatsWidget()
        FluentryWordWidget()
    }
}
