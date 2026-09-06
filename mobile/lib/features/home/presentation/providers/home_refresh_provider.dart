// lib/features/home/presentation/providers/home_refresh_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Incremented whenever the user taps the Home icon while already on the Home tab
final homeRefreshSignalProvider = StateProvider<int>((ref) => 0);
