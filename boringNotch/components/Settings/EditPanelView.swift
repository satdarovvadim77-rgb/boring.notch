//
//  EditPanelView.swift
//  boringNotch
//
//  Created by Richard Kunkli on 12/08/2024.
//

import SwiftUI

struct EditPanelView: View {
    @State var wallpaperPath: URL?
    var body: some View {
        VStack {
            HStack {
                Text("Edit layout")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Button {
                    exit(0)
                } label: {
                    Label("Close", systemImage: "xmark")
                }
                .controlSize(.extraLarge)
                .buttonStyle(AccessoryBarButtonStyle())
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    EditPanelView()
}
