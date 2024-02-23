///
//  HeartbeatView.swift
//  DittoSwiftTools
//
//  Created by Eric Turner on 02/01/24.
//
//  Copyright © 2024 DittoLive Incorporated. All rights reserved.

import Combine
import DittoSwift
import SwiftUI


@available(iOS 15, *)
private class PrivateHeartbeatVM: ObservableObject {
    @Published private(set) var infoDocs = [DittoHeartbeatInfo]()
    @Published fileprivate var isPaused = true
    
    @ObservedObject private var hbVM: HeartbeatVM
    var config: DittoHeartbeatConfig
    private var cancellable = AnyCancellable({})
    private var infoObserver: DittoStoreObserver?
    private let ditto: Ditto
    private let collName = "devices" // default
    private let queryString: String
    
    init(ditto: Ditto, config: DittoHeartbeatConfig) {
        self.ditto = ditto
        self.config = config
        hbVM = HeartbeatVM(ditto: ditto)
        queryString = "SELECT * FROM \(collName)"
        
        cancellable = $isPaused
            .sink {[weak self] paused in
                guard let self = self else { return }
                if paused {
                    stopHeartbeat()
                } else {
                    startHeartbeat()
                }
            }
    }
    
    func startHeartbeat() {
        hbVM.startHeartbeat(ditto: ditto, config: DittoHeartbeatConfig.mock) { [weak self] info in
            guard let self = self else { return }
            if infoObserver == nil {
               startInfoObserver()
            }
        }
    }
    
    func stopHeartbeat() {
        hbVM.stopHeartbeat()
    }
    
    private func startInfoObserver() {
        infoObserver = try? ditto.store.registerObserver(query: queryString) {[weak self] result in
            guard let self = self else { return }
            
            let docs = result.items.compactMap { item in
                DittoHeartbeatInfo(item.value)
            }
            infoDocs = docs
        }
    }
}

@available(iOS 15, *)
public struct HeartbeatView: View {
    @StateObject fileprivate var vm: PrivateHeartbeatVM
    private let dividerColor: Color = .accentColor
    
    public init(ditto: Ditto, config: DittoHeartbeatConfig) {
        _vm = StateObject(
            wrappedValue: PrivateHeartbeatVM(ditto: ditto, config: config)
        )
    }
    
    public var body: some View {
        VStack {
            List {
                ForEach(vm.infoDocs) { info in
                    HeartbeatInfoRowItem(info: info)
                }
            }
        }
        .onDisappear { vm.stopHeartbeat() }
        .navigationTitle(String.hbInfoTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    vm.isPaused.toggle()
                } label: {
                    Image(systemName: vm.isPaused ? String.imgPlay : String.imgPause)
                        .symbolRenderingMode(.multicolor)
                }
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .buttonStyle(.borderless)
            }
        }
    }
}
