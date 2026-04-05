import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
