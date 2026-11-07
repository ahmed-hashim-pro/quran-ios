//
//  DataUnavailableView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

import Localization
import SwiftUI

public struct DataUnavailableView: View {
    // MARK: Lifecycle

    /// `action`, when given, is a button below the text that offers a way forward.
    public init(title: String, text: String, image: NoorSystemImage, action: (title: String, perform: () -> Void)? = nil) {
        self.title = title
        self.text = text
        self.image = image
        self.action = action
    }

    // MARK: Public

    public var body: some View {
        GeometryReader { proxy in
            VStack {
                image.image
                    .font(.largeTitle)
                    .imageScale(.large)
                Text(title)
                    .font(.headline)
                    .padding()
                Text(text)
                    .multilineTextAlignment(.center)
                if let action {
                    Button(action.title, action: action.perform)
                        .buttonStyle(.borderedProminent)
                        .padding()
                }
            }
            .foregroundColor(.secondaryLabel)
            .padding(.horizontal)
            .offset(y: proxy.size.height / 4)
            .frame(maxWidth: .infinity)
        }
        .background(Color.systemGroupedBackground)
        .ignoresSafeArea()
    }

    // MARK: Internal

    let title: String
    let text: String
    let image: NoorSystemImage
    let action: (title: String, perform: () -> Void)?
}

struct DataUnavailableView_Previews: PreviewProvider {
    static var previews: some View {
        DataUnavailableView(
            title: l("bookmarks.no-data.title"),
            text: l("bookmarks.no-data.text"),
            image: .bookmark
        )
    }
}
