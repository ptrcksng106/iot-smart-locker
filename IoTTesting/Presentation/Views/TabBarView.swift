//
//  TabBarView.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            LockerView()
                .tabItem {
                    Image(systemName: "lock.fill")
                    
                    Text("Locker")
                }
            
            VerifyLockerView()
                .tabItem {
                    Image(systemName: "checkmark.seal.fill")
                    
                    Text("Verify")
                }
        }
    }
}

#Preview {
    TabBarView()
}

