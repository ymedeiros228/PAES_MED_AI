// Implementacao web — registra iframe como platform view
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

void registerPdfView(String viewId, String url) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int _) => html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'fullscreen',
  );
}
