import 'package:flutter_web_plugins/url_strategy.dart';

/// Configures clean path-based URL strategy on Flutter Web so routes match
/// browser paths (e.g. `/jj` and `/u/:userId`) without hash fragments (`/#/`).
void configureUrlStrategy() {
  usePathUrlStrategy();
}
