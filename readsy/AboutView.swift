//
//  AboutView.swift
//  readsy
//
//  Created by Jeremy Brooks on 1/3/25.
//

import SwiftUI

struct AboutView: View {
    @State private var readsyExpanded = false
    @State private var zipExpanded = false
    
    var body: some View {
        VStack {
            ScrollView {
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
                        Text("Readsy")
                            .font(.title)
                        Text("Read something every day")
                            .italic()
                        Spacer()
                        Text("Version \(appVersion())")
                            .font(.footnote)
                    }
                    .padding(.leading)
                }
                .padding(.bottom)
                Divider()
                HStack() {
                    Text("Book Storage: ")
                        .font(.headline)
                    Text(UserDefaults.standard.bool(forKey: UserDefaultsKeys.useiCloud) ? "iCloud" : "Local")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider()
                Label("If you have questions about Readsy, [visit the web site](https://jeremybrooks.net/readsy).", systemImage: "safari")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                Label("If you need help, you can [email the developer](mailto:readsy@jeremybrooks.net).", systemImage: "envelope")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom)
                Divider()
                Text(
                    "Readsy is Copyright © 2013-2025 Jeremy Brooks."
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                DisclosureGroup("View Readsy License", isExpanded: $readsyExpanded) {
                        Text(
                            """
                            Copyright (c) 2013-2025 Jeremy Brooks

                            This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

                            This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

                            You should have received a copy of the GNU General Public License along with this program.  If not, see [https://www.gnu.org/licenses/](https://www.gnu.org/licenses/).
                            """
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                
                Divider()
                Text("Readsy uses ZipFoundation")
                    .frame(maxWidth: .infinity, alignment: .leading)
                DisclosureGroup("View ZipFoundation License", isExpanded: $zipExpanded) {
                    Text(
                        """
                        Copyright (c) 2017-2024 Thomas Zoechling (https://www.peakstep.com)
                                         
                        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

                        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

                        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
                        """)
                    }
                Spacer()
            }
        }
        .padding()
        .navigationTitle("About")
        .toolbarTitleDisplayMode(.inline)
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
    private func appVersion(in bundle: Bundle = .main) -> String {
        let version =
            bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "?"
        let build =
            bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            ?? "?"
        return "\(version) (\(build))"
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
