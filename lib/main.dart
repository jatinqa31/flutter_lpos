import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: set a custom data directory to reduce permission prompts on Android
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Web App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WebContainer(),
    );
  }
}

class WebContainer extends StatefulWidget {
  const WebContainer({super.key});

  @override
  State<WebContainer> createState() => _WebContainerState();
}

class _WebContainerState extends State<WebContainer> {
  final String initialUrl = "https://www.lexerpos.com"; // <- change this
  InAppWebViewController? _controller;
  late PullToRefreshController _pullToRefreshController;

  double _progress = 0.0;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();

    _pullToRefreshController = PullToRefreshController(
      onRefresh: () async {
        if (Platform.isAndroid) {
          await _controller?.reload();
        } else if (Platform.isIOS) {
          final url = await _controller?.getUrl();
          if (url != null) {
            await _controller?.loadUrl(urlRequest: URLRequest(url: url));
          }
        }
      },
    );
  }

  Future<void> _updateBackStatus() async {
    final canGoBack = await _controller?.canGoBack() ?? false;
    setState(() => _canGoBack = canGoBack);
  }

  NavigationActionPolicy _handleExternalSchemes(Uri uri) {
    // Handle tel:, mailto:, sms:, intent://, and non-http(s) URLs externally
    if (!["http", "https", "file", "chrome", "data", "javascript", "about"]
        .contains(uri.scheme)) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  @override
  Widget build(BuildContext context) {
    final safeArea = MediaQuery.of(context).padding;

    return PopScope(
      canPop: !_canGoBack, // Android "back" behavior
      onPopInvoked: (didPop) async {
        if (!didPop && _canGoBack) {
          await _controller?.goBack();
          _updateBackStatus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Web App"),
          actions: [
            IconButton(
              onPressed: () => _controller?.reload(),
              icon: const Icon(Icons.refresh),
              tooltip: "Reload",
            ),
          ],
        ),
        body: SafeArea(
          top: true,
          bottom: true,
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
                pullToRefreshController: _pullToRefreshController,
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  allowsInlineMediaPlayback: true,
                  mediaPlaybackRequiresUserGesture: false,
                  // If you need camera/mic inside iframes (video calls, etc.)
                  iframeAllow: "camera; microphone; fullscreen",
                  iframeAllowFullscreen: true,
                  useOnDownloadStart: true,
                  clearCache: false,
                  cacheEnabled: true,
                  sharedCookiesEnabled: true,
                  verticalScrollBarEnabled: true,
                  horizontalScrollBarEnabled: false,
                  transparentBackground: false,
                  // iOS-specific tuning
                  // allowsBackForwardNavigationGestures: true,
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                onLoadStart: (controller, url) => _updateBackStatus(),
                onLoadStop: (controller, url) async {
                  _pullToRefreshController.endRefreshing();
                  _updateBackStatus();
                },
                onProgressChanged: (controller, progress) {
                  setState(() => _progress = progress / 100.0);
                },
                shouldOverrideUrlLoading:
                    (controller, navigationAction) async {
                  final uri = navigationAction.request.url;
                  if (uri != null) {
                    return _handleExternalSchemes(uri);
                  }
                  return NavigationActionPolicy.ALLOW;
                },
                onPermissionRequest: (controller, request) async {
                  // Auto-grant camera/mic while inside the webview
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onReceivedServerTrustAuthRequest:
                    (controller, challenge) async {
                  // If your SSL is valid, you won't hit this. For dev/self-signed:
                  return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.PROCEED,
                  );
                },
                onDownloadStartRequest:
                    (controller, downloadStartRequest) async {
                  // You can implement custom download handling here if needed.
                  final uri = downloadStartRequest.url;
                  if (uri != null) {
                    await launchUrl(Uri.parse(uri.toString()),
                        mode: LaunchMode.externalApplication);
                  }
                },
              ),
              if (_progress < 1.0)
                Positioned(
                  top: safeArea.top,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(value: _progress),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
