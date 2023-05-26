//
//  MenuListItem.swift
//  Pluto
//
//  Created by Maximilian Alexander on 9/3/21.
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

struct MenuListItem_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView{
            List {
                Section("Debug") {
                    MenuListItem(title: "Data Browser", systemImage: "photo", color: .orange)
                    MenuListItem(title: "Peers List", systemImage: "network", color: .blue)
                    MenuListItem(title: "Presence Viewer", systemImage: "network", color: .pink)
                    MenuListItem(title: "Disk Usage", systemImage: "opticaldiscdrive", color: .secondary)
                }
                Section("Change Identity") {
                    MenuListItem(title: "Change Identity", systemImage: "envelope", color: .purple)
                }
                Section("Exports") {
                    MenuListItem(title: "Export Logs", systemImage: "square.and.arrow.up", color: .green)
                    MenuListItem(title: "Export Logs", systemImage: "square.and.arrow.up", color: .green)
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("DittoTools")
        }
        .preferredColorScheme(.dark)
    }
}
