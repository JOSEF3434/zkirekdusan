import 'package:web/web.dart' as web;

void requestBrowserFullscreen() {
  try {
    if (web.document.fullscreenElement == null) {
      web.document.documentElement?.requestFullscreen();
    }
  } catch (_) {}
}

void exitBrowserFullscreen() {
  try {
    if (web.document.fullscreenElement != null) {
      web.document.exitFullscreen();
    }
  } catch (_) {}
}
