import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Manages web browser context menu suppression for message areas.
///
/// On Flutter Web:
/// When the cursor enters a message bubble or its context menu, we disable
/// the browser's native context menu via [BrowserContextMenu.disableContextMenu].
/// This ensures that when the user right-clicks a message, only our custom
/// Flutter context menu appears and Chrome's native context menu is suppressed
/// with preventDefault().
///
/// When the cursor leaves the message bubble and no custom dialog is open,
/// we re-enable the browser's native context menu via [BrowserContextMenu.enableContextMenu].
/// This guarantees that right-clicking anywhere else in the app (input fields,
/// sidebar, app bar, navigation, text selection) retains the normal browser behavior.
class WebContextMenuManager {
  static int _activeHoverCount = 0;
  static bool _isDialogOpen = false;

  /// Called when the mouse pointer enters a message bubble or message container.
  static void onMessagePointerEnter() {
    if (!kIsWeb) return;
    _activeHoverCount++;
    _applyState();
  }

  /// Called when the mouse pointer hovers over a message bubble.
  static void onMessagePointerHover() {
    if (!kIsWeb) return;
    if (_activeHoverCount <= 0) {
      _activeHoverCount = 1;
      _applyState();
    }
  }

  /// Called when the mouse pointer exits a message bubble or message container.
  static void onMessagePointerExit() {
    if (!kIsWeb) return;
    _activeHoverCount = (_activeHoverCount - 1).clamp(0, 999999);
    _applyState();
  }

  /// Called on pointer down (especially secondary / right button) to ensure
  /// the browser menu is suppressed even if hover wasn't registered beforehand.
  static void onSecondaryPointerDown() {
    if (!kIsWeb) return;
    BrowserContextMenu.disableContextMenu();
  }

  /// Called when the custom message options dialog opens.
  static void onCustomMenuOpened() {
    if (!kIsWeb) return;
    _isDialogOpen = true;
    _applyState();
  }

  /// Called when the custom message options dialog closes.
  static void onCustomMenuClosed() {
    if (!kIsWeb) return;
    _isDialogOpen = false;
    _applyState();
  }

  static void _applyState() {
    if (!kIsWeb) return;
    if (_activeHoverCount > 0 || _isDialogOpen) {
      BrowserContextMenu.disableContextMenu();
    } else {
      BrowserContextMenu.enableContextMenu();
    }
  }
}
