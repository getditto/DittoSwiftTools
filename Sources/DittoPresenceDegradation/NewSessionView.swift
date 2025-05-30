//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 2/13/24.
//

import SwiftUI
#if os(tvOS)
import UIKit
import DittoTvOSTextFieldComponent
#endif

public struct NewSessionView: View {
    
    @Binding private var expectedPeers: String
    @Binding private var apiEnabled: Bool
    @Binding var isPresented: Bool
    @Binding var sessionStartTime: String?
    @State private var tempExpectedPeers: String = ""
    @State private var showAlert = false
    @State private var isEditing = false

    var onDismiss: () -> Void
    
    public init(
        expectedPeers: Binding<String>,
        apiEnabled: Binding<Bool>,
        isPresented: Binding<Bool>,
        sessionStartTime: Binding<String?>,
        onDismiss: @escaping () -> Void
    ) {
        self._expectedPeers = expectedPeers
        self._apiEnabled = apiEnabled
        self._isPresented = isPresented
        self._sessionStartTime = sessionStartTime
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        
        Group {
            #if os(macOS)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    expectedPeersSection
                    apiToggleSection
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding()
            }
            #else
            Form {
                expectedPeersSection
                apiToggleSection
            }
            #endif
        }
        .navigationTitle("New Session")

        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif

        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                saveButton
            }
        }

        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Invalid Input"),
                message: Text("Expected peer count must be greater than 0."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Subviews

    private var expectedPeersSection: some View {
        #if os(iOS)
        Section {
            TextField("Enter Number", text: $tempExpectedPeers)
                .keyboardType(.numberPad)
        } header: {
            Text("Expected Peer Count")
        } footer: {
            Text("Define the minimum number of required peers to be connected. Must be at least 1.")
                .font(.footnote)
        }
        #elseif os(macOS)
        Section {
            VStack(alignment: .leading) {
                Text("Expected Peer Count")
                    .font(.headline)
                TextField("Enter number", text: $tempExpectedPeers)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: 200)
            }
        } footer: {
            Text("Define the minimum number of required peers to be connected. Must be at least 1.")
                .font(.footnote)
                .padding(.top, -16)
        }
        #else
        Section {
            Button(action: {
                isEditing = true
            }) {
                HStack {
                    Text("Expected Peer Count")
                    Spacer()
                    Text(tempExpectedPeers)
                    Image(systemName: "chevron.right")
                }
            }
            .background(KeyboardOverlay(text: $tempExpectedPeers, isPresented: $isEditing, keyboardType: .numberPad))
        } footer: {
            Text("Define the minimum number of required peers to be connected. Must be at least 1.")
                .font(.footnote)
        }
        #endif
    }

    private var apiToggleSection: some View {
        Section {
            Toggle("Enable Report API", isOn: $apiEnabled)
        } footer: {
            Text("Allows the session to receive updates and report mesh presence status via a callback.")
                .font(.footnote)
                #if os(macOS)
                .padding(.top, -16)
                #endif
        }
    }
    
    private var saveButton: some View {
        #if os(macOS)
        Button(action: saveSession) {
            Text("Save")
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .foregroundColor(Color.primary)
        }
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        #else
        Button(action: saveSession) {
            Text("Save").bold()
        }
        #endif
    }

    // MARK: - Logic

    private func saveSession() {
        guard Int(tempExpectedPeers) ?? 0 > 0 else {
            showAlert = true
            return
        }
        expectedPeers = tempExpectedPeers
        sessionStartTime = getStartTime()
        isPresented = false
        onDismiss()
    }
}

// MARK: - Utility

private func getStartTime() -> String {
    DateFormatter.isoDate.string(from: Date())
}
