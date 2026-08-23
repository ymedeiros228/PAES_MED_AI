/// Implementação web: abre URL no browser via window.open (JS interop).
library;

import 'dart:js_interop';

@JS('window.open')
external void _windowOpen(String url, [String? target]);

void openUrlInBrowser(String url) {
  _windowOpen(url, '_blank');
}
