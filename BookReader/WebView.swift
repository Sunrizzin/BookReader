import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    var htmlContent: String
    var baseURL: URL?
    var cssContent: String
    var colorScheme: ColorScheme
    
    var configuration: WKWebViewConfiguration = WKWebViewConfiguration()
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Finished loading content")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        configuration.selectionGranularity = .dynamic
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let additionalCSS = colorScheme == .dark ? """
                    body {
                        background-color: black;
                        color: white;
                    }
                """ : """
                    body {
                        background-color: white;
                        color: black;
                    }
                """
        
        let htmlWithCSS = """
                <html>
                <head>
                <style>
                \(cssContent)
                \(additionalCSS)
                </style>
                </head>
                <body>
                \(htmlContent)
                </body>
                </html>
                """
        
        uiView.loadHTMLString(htmlWithCSS, baseURL: baseURL)
    }
}
