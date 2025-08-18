import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyWebApp());
}

class MyWebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebView App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WebViewHome(),
    );
  }
}

class WebViewHome extends StatefulWidget {
  @override
  _WebViewHomeState createState() => _WebViewHomeState();
}

class _WebViewHomeState extends State<WebViewHome> {
  late final WebViewController _controller;
  final TextEditingController _urlController = TextEditingController(text: 'https://www.lexerpos.com');

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            // Show any custom error UI here
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter valid Customer ID. To get your Customer ID, buy LexerPOS at www.lexerpos.com'))
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(_urlController.text));
  }

  void _loadUrl() {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      _controller.loadRequest(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WebView App'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              // Show menu (use PopupMenuButton for options)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Enter URL',
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadUrl,
                  child: Text('Load'),
                ),
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
