//
//  MenuListItem.swift
//
//

import SwiftUI

struct ColorfulIconLabelStyle: LabelStyle {
    var color: Color
    var size: CGFloat
    var foregroundColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .imageScale(.small)
                .foregroundColor(foregroundColor)
                .background(RoundedRectangle(cornerRadius: 7 * size).frame(width: 28 * size, height: 28 * size).foregroundColor(color))
        }
    }
}

struct MenuListItem: View {

    @ScaledMetric var size: CGFloat = 1

    var title: String
    var systemImage: String
    var color: Color = .accentColor
    var foregroundColor: Color = .white

    var body: some View {
        Label(title, systemImage: systemImage)
            .labelStyle(ColorfulIconLabelStyle(color: color, size: size, foregroundColor: foregroundColor))
    }
}

