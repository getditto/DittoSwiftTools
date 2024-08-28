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

private class PrivateHeartbeatVM: ObservableObject {
    @Published private(set) var infoDocs = [DittoHeartbeatInfo]()
    @Published fileprivate var isPaused = true
    
    @ObservedObject private var hbVM: HeartbeatVM
    var config: DittoHeartbeatConfig?
    private var cancellable = AnyCancellable({})
    private var infoObserver: DittoStoreObserver?
    private let ditto: Ditto
    private let collName = String.collectionName // default
    private let queryString: String
    
    init(ditto: Ditto, config: DittoHeartbeatConfig?) {
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
        // Use mock config for demo if nil
        let hbConfig = config ?? DittoHeartbeatConfig.mock
        
        hbVM.startHeartbeat(config: hbConfig) { [weak self] info in
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
            withAnimation {
                self.infoDocs = docs
            }
        }
    }
}

public struct HeartbeatView: View {
    @StateObject fileprivate var vm: PrivateHeartbeatVM
    private let dividerColor: Color = .accentColor
    
    public init(ditto: Ditto, config: DittoHeartbeatConfig? = nil) {
        _vm = StateObject(
            wrappedValue: PrivateHeartbeatVM(ditto: ditto, config: config)
        )
    }
    
    public var body: some View {
        VStack {
            if vm.isPaused && vm.infoDocs.count < 1 {
                VStack(alignment: .center) {
                    Text(String.getStartedText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                    
                    Button(action: {
                        vm.isPaused.toggle()
                    }, label: {
                        Image(systemName: String.imgPlay)
                            .font(.system(size: 60))
                    })
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(vm.infoDocs) { info in
#if !os(tvOS)
                        HeartbeatInfoRowItem(info: info)
#endif
                    }
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
                }
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .buttonStyle(.automatic)
            }
        }
    }
}
