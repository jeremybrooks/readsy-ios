//
//  WelcomeView.swift
//  readsy
//
//  Created by Jeremy Brooks on 2/13/25.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage(UserDefaultsKeys.useiCloud) var useiCloud = UserDefaults.standard.bool(forKey: UserDefaultsKeys.useiCloud)
    
    var library: Library

    var body: some View {
        HStack {
            VStack {
                if let image = UIImage(named: appIcon()) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            VStack(alignment: .leading) {
                Text("Welcome to Readsy!")
                    .font(.title)
            }
            .padding(.leading)
        }
        VStack {
            Text("Readsy helps you read something every day.\n\nYou can store your library in iCloud or locally on your device. Using iCloud is recommended. You will then be able to read your books on any device, and your progress will be synced.")
                .padding()

            Toggle("Use iCloud for Storage", isOn: $useiCloud)
                .padding()
            Spacer()
            Button(action: {
                UserDefaults.standard.set(false, forKey: UserDefaultsKeys.onboardingNeeded)
                // attempt to load the library
                // this will ensure that if a user deleted the app, then reinstalled,
                // they will see their shared library when onboarding is complete
                do {
                    try DataManager.shared.loadLibrary(library)
                } catch {
                    // ignore errors here
                }
                dismiss()
            }, label: {
                    Label("Start Using Readsy", systemImage: "book")
            })
        }
    }
    private func appIcon(in bundle: Bundle = .main) -> String {
        guard
            let icons = bundle.object(forInfoDictionaryKey: "CFBundleIcons")
                as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let iconFileName = iconFiles.last
        else {
            return ""
        }

        return iconFileName
    }
}

#Preview {
    let library = Library()
    WelcomeView(library: library)
}
