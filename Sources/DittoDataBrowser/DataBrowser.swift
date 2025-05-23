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
    @State var isShowingModal: Bool = false
    #if os(tvOS)
    @FocusState private var focusedButton: ButtonFocus?
    
    enum ButtonFocus: Hashable {
        case cancel, start
    }
    #endif
    @State private var isHovered = false
    
    public init(ditto: Ditto) {
        self._viewModel = StateObject(wrappedValue: DataBrowserViewModel(ditto: ditto))
    }
    
    public var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                // macOS requires a NavigationView for Lists to work
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
            .onDisappear(perform: {
                viewModel.closeLiveQuery()
            })
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    // Hides startPauseButton so it doesn't interfere with modal on tvOS
                    #if os(tvOS)
                    if !isShowingModal {
                        startPauseButton
                    }
                    #else
                    startPauseButton
                    #endif
                }
            }
            .disabled(self.isShowingModal)
            // Sheet works best on macOS for popup (for current versions). ZStack works best on iOS and tvOS for popups (for current versions).
            #if os(macOS)
            .sheet(isPresented: $isShowingModal) {
                modalView
            }
            #endif
            #if os(iOS) || os(tvOS)
            if self.isShowingModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .transition(.opacity)

                modalView
                    .transition(.scale)
                    .zIndex(1)
            }
            #endif
        }
        .animation(.easeInOut, value: self.isShowingModal)
    }
    
    private var listView: some View {
        List {
            Section {
                ForEach(viewModel.collections ?? [], id: \.name) { collection in
                    NavigationLink(destination: Documents(collectionName: collection.name, ditto: viewModel.ditto, isStandAlone: self.isStandAlone)) {
                        Text(collection.name)
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
    
    private var spacingInteger: CGFloat {
        #if os(iOS) || os(macOS)
        return 20
        #else
        return 40
        #endif
    }
    
    private var modalView: some View {
        VStack(spacing: spacingInteger / 2) {
            Text("Standalone App?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            Text("Only start subscriptions if using the Data Browser in a standalone app.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack(spacing: spacingInteger) {
                cancelButton
                startButton
            }
            .padding(.top, 8)
        }
        .padding()
        #if os(iOS)
        .frame(maxWidth: 400)
        .background(Color(UIColor.systemGray6))
        #elseif os(macOS)
        .frame(maxWidth: 300)
        .background(Color.clear)
        #else
        .padding()
        .frame(maxWidth: 800)
        .background(Color.gray.opacity(0.3))
        .onAppear {
            DispatchQueue.main.async {
                focusedButton = .cancel
            }
        }
        #endif
        #if !os(macOS)
        .cornerRadius(24)
        .shadow(radius: 20)
        #endif
        #if os(iOS)
        .padding()
        #endif
    }
    
    private var startPauseButton: some View {
        Button {
            if self.startSubscriptions {
                self.startSubscriptions = false
                viewModel.closeLiveQuery()
            } else {
                self.isShowingModal = true
            }
        } label: {
            #if os(iOS)
            Image(systemName: self.startSubscriptions ? "pause.circle" : "play.circle")
                .font(.system(size: 24))
                .animation(.none)
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

    
    private var startButton: some View {
        Button(action: start) {
            Text("Start")
                .frame(maxWidth: .infinity)
                #if os(iOS)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                #elseif os(tvOS)
                .focusable(true)
                .focused($focusedButton, equals: .start)
                #endif
        }
    }

    private var cancelButton: some View {
        Button {
            self.isShowingModal = false
        } label: {
            Text("Cancel")
                .frame(maxWidth: .infinity)
                #if os(iOS)
                .padding()
                .background(Color(UIColor.systemGray5))
                .foregroundColor(.blue)
                .cornerRadius(10)
                #elseif os(tvOS)
                .focusable(true)
                .focused($focusedButton, equals: .cancel)
                #endif
        }
    }
    
    private func start() {
        self.startSubscriptions = true
        viewModel.startSubscription()
        self.isStandAlone = true
        self.isShowingModal = false
    }
}

