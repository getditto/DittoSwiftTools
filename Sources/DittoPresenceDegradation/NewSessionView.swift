//
//  SwiftUIView.swift
//  
//
//  Created by Walker Erekson on 2/13/24.
//

import SwiftUI

@available(iOS 14.0, *)
public struct NewSessionView: View {
    
    @Binding private var expectedPeers: Int
    @Binding private var apiEnabled: Bool
    @Binding var isPresented: Bool
    @Binding var sessionStartTime: String?
    @State private var showAlert = false
    var onDismiss: () -> Void
    
    public init(expectedPeers: Binding<Int>, apiEnabled: Binding<Bool>, isPresented: Binding<Bool>, sessionStartTime: Binding<String?>, onDismiss: @escaping () -> Void) {
        self._expectedPeers = expectedPeers
        self._apiEnabled = apiEnabled
        self._isPresented = isPresented
        self._sessionStartTime = sessionStartTime
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            HStack() {
                Text("Expected peer count in the mesh:")
                TextField("0", value: $expectedPeers, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .frame(maxWidth: 50)

            }
            .padding()
            HStack() {
                Toggle(isOn: $apiEnabled, label: {
                    Text("Enable Report API")
                })
            }
            .padding()
            
            Button{
                if self.expectedPeers > 0 {
                    self.sessionStartTime = getStartTime()
                    self.isPresented = false
                    self.onDismiss()
                } else {
                    self.showAlert.toggle()
                }
            } label: {
                Text("Save")
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                    )
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Alert"), message: Text("Expected peer count must be a number greater than 0"), dismissButton: .default(Text("OK")))
            }
        }
    }
}

func getStartTime() -> String {
    return DateFormatter.isoDate.string(from: Date())
}


