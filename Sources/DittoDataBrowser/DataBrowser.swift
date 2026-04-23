//
//  DataBrowserApp.swift
//  DataBrowser
//
//  Created by Walker Erekson on 11/3/22.
//

import SwiftUI
import DittoSwift

public struct DataBrowser: View {
    
    @StateObject var viewModel: DataBrowserViewModel
    @State var startSubscriptions: Bool = false
    @State var isStandAlone: Bool = false
    @State var isShowingAlert: Bool = false
    @State private var isHovered = false
    
    public init(ditto: Ditto) {
        self._viewModel = StateObject(wrappedValue: DataBrowserViewModel(ditto: ditto))
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            #if os(macOS)
            NavigationView {
                listView
            }
            #else
            listView
            #endif
        }
        .navigationTitle("Collections")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                startPauseButton
            }
        }
        .disabled(isShowingAlert)
        .alert(isPresented: $isShowingAlert) {
            Alert(
                title: Text("Standalone App?"),
                message: Text("Only start subscriptions if using the Data Browser in a standalone app."),
                primaryButton: .default(
                    Text("Start"),
                    action: start
                ),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    private var listView: some View {
        List {
            Section {
                ForEach(viewModel.collections, id: \.self) { name in
                    NavigationLink(destination: Documents(collectionName: name, ditto: viewModel.ditto, isStandAlone: self.isStandAlone)) {
                        Text(name)
                    }
                }
            }
        }
        #if os(iOS)
        .padding(.top, -16)
        #elseif os(tvOS)
        .padding(.top, 16)
        #endif
    }
    
    private var startPauseButton: some View {
        Button {
            if self.startSubscriptions {
                self.startSubscriptions = false
                viewModel.closeLiveQuery()
            } else {
                self.isShowingAlert = true
            }
        } label: {
            #if os(iOS)
            Image(systemName: self.startSubscriptions ? "pause.circle" : "play.circle")
                .font(.system(size: 24))
            #else
            Text(self.startSubscriptions ? "Pause Subscriptions" : "Start Subscriptions")
                #if os(macOS)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .foregroundColor(Color.primary)
                #endif
            #endif
        }
        #if os(macOS)
        .background(Color.blue.opacity(isHovered ? 1 : 0.75))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onHover { hovering in
            isHovered = hovering
        }
        .animation(.easeInOut(duration: 0.1), value: isHovered)
        #endif
    }

    private func start() {
        self.startSubscriptions = true
        viewModel.startSubscription()
        self.isStandAlone = true
        self.isShowingAlert = false
    }
}

