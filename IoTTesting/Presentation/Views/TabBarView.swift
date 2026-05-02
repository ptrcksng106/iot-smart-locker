//
//  TabBarView.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import SwiftUI

struct TabBarView: View {
    @StateObject private var modeManager = UserModeManager.shared

    var body: some View {
        TabView {
            if modeManager.currentMode == .courier {
                LockerView()
                    .tabItem {
                        Image(systemName: "shippingbox.fill")
                        Text("Courier")
                    }
            }

            if modeManager.currentMode == .receiver {
                ReceiverOrdersView()
                    .tabItem {
                        Image(systemName: "arrow.down.to.line.circle.fill")
                        Text("Pick Up")
                    }
            }

            VerifyLockerView()
                .tabItem {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Verify")
                }
        }
        .overlay(alignment: .top) {
            ModeToggleButton()
        }
    }
}

struct ModeToggleButton: View {
    @StateObject private var modeManager = UserModeManager.shared

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: modeManager.currentMode.icon)
                .font(.system(size: 14, weight: .semibold))

            Text(modeManager.currentMode.rawValue)
                .font(.system(size: 14, weight: .semibold))

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 12))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(modeManager.currentMode == .courier ? Color.blue : Color.green)
        )
        .padding(.top, 8)
        .onTapGesture {
            modeManager.toggle()
        }
    }
}

#Preview {
    TabBarView()
}

