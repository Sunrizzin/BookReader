//
//  WebView.swift
//  BookReader
//
//  Created by Sunrizz on 27.09.2024.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    var htmlContent: String
    var baseURL: URL?
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: baseURL)
    }
}
