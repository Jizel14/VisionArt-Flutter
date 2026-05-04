import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class CheckoutWebviewScreen extends StatefulWidget {
  const CheckoutWebviewScreen({
    super.key,
    required this.checkoutUrl,
    required this.onSuccess,
    required this.onCancel,
  });

  final String checkoutUrl;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  State<CheckoutWebviewScreen> createState() => _CheckoutWebviewScreenState();
}

class _CheckoutWebviewScreenState extends State<CheckoutWebviewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _useExternalBrowser = false;

  @override
  void initState() {
    super.initState();
    final isMobile = Platform.isAndroid || Platform.isIOS;
    if (!isMobile) {
      _useExternalBrowser = true;
      _isLoading = false;
      // Desktop/Linux: webview_flutter has no platform implementation → open browser instead.
      _openExternal();
      return;
    }

    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) => setState(() => _isLoading = true),
            onPageFinished: (_) => setState(() => _isLoading = false),
            onWebResourceError: (error) {
              setState(() => _isLoading = false);
            },
            onNavigationRequest: (request) {
              final url = request.url;

              // Intercept deep links BEFORE the browser opens them
              if (url.startsWith('visionart://subscription/success')) {
                _handleSuccess();
                return NavigationDecision.prevent;
              }
              if (url.startsWith('visionart://subscription/cancel')) {
                _handleCancel();
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.checkoutUrl));
    } catch (_) {
      // Safety net: if platform webview is not initialized for any reason,
      // fallback to external browser.
      _useExternalBrowser = true;
      _isLoading = false;
      _openExternal();
    }
  }

  Future<void> _openExternal() async {
    final uri = Uri.parse(widget.checkoutUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open browser for checkout.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleSuccess() {
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are now a Pro member!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _handleCancel() {
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onCancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Upgrade canceled.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
            widget.onCancel();
          },
        ),
      ),
      body: Stack(
        children: [
          if (_useExternalBrowser)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.open_in_browser, size: 44),
                    const SizedBox(height: 12),
                    const Text(
                      'Checkout opened in your browser',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'On desktop, the in-app WebView is not supported.\nComplete the payment in the browser, then return here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _openExternal,
                      child: const Text('Open checkout again'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onSuccess();
                      },
                      child: const Text("I've paid → Refresh status"),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onCancel();
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
