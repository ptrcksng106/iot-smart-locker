//
//  PrimaryButton.swift
//  IoTTesting
//
//  Created by Patrick Samuel Owen Saritua Sinaga on 16/04/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    var onTapped:() -> Void?
    
    var body: some View {
        Button("Get Lockers") {
            onTapped()
        }
        .foregroundStyle(.white)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.blue)
        )
    }
}

#Preview {
    PrimaryButton(title: "Button") {
        
    }
}
