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
    
    // Возможность передать конфигурацию
    var configuration: WKWebViewConfiguration = WKWebViewConfiguration()
    
    // Класс делегата для отслеживания ошибок и прогресса
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("Error loading web content: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Finished loading content")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        configuration.selectionGranularity = .character
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: baseURL)
    }
}
