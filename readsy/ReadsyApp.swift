//
//  readsyApp.swift
//  readsy
//
//  Created by Jeremy Brooks on 11/27/24.
//

import SwiftUI

@main
struct ReadsyApp: App {
    
    init() {
        // set up UserDefaults values if they do not exist
        if (UserDefaults.standard.object(forKey: UserDefaultsKeys.useiCloud) == nil) {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.useiCloud)
        }
        if (UserDefaults.standard.object(forKey: UserDefaultsKeys.onboardingNeeded) == nil) {
            UserDefaults.standard.set(true, forKey: UserDefaultsKeys.onboardingNeeded)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            LibraryView().navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
