// lib/features/security/presentation/pattern_setup_screen.dart
//
// Two-step pattern setup: draw → confirm.
// Requires [kMinPatternNodes] or more nodes.
// On success, saves the pattern hash and enables App Lock.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/security/data/pattern_service.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_settings_provider.dart';
import 'package:mobile/features/security/presentation/providers/app_lock_provider.dart';
import 'package:mobile/features/security/presentation/widgets/pattern_lock_widget.dart';

class PatternSetupScreen extends ConsumerStatefulWidget {
  /// If true, the screen is shown for changing an existing pattern.
  final bool isChange;

  const PatternSetupScreen({super.key, this.isChange = false});

  @override
  ConsumerState<PatternSetupScreen> createState() => _PatternSetupScreenState();
}

class _PatternSetupScreenState extends ConsumerState<PatternSetupScreen>
    with SingleTickerProviderStateMixin {
  List<int>? _firstPattern;
  bool _confirming = false;
  String? _errorMessage;
  PatternLockState _lockState = PatternLockState.idle;

  final GlobalKey<PatternLockWidgetState> _patternKey = GlobalKey();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onPatternComplete(List<int> nodes) async {
    if (!_confirming) {
      // Step 1: record the first pattern
      setState(() {
        _firstPattern = List.from(nodes);
        _errorMessage = null;
        _lockState = PatternLockState.success;
      });
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _confirming = true;
          _lockState = PatternLockState.idle;
        });
        _patternKey.currentState?.reset();
      }
    } else {
      // Step 2: verify confirmation
      if (_listsEqual(nodes, _firstPattern!)) {
        setState(() => _lockState = PatternLockState.success);
        await Future.delayed(const Duration(milliseconds: 300));
        await _savePattern(nodes);
      } else {
        setState(() {
          _lockState = PatternLockState.error;
          _errorMessage = 'Patterns do not match. Please try again.';
        });
        _shakeController.forward(from: 0);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _confirming = false;
            _firstPattern = null;
            _lockState = PatternLockState.idle;
          });
          _patternKey.currentState?.reset();
        }
      }
    }
  }

  bool _listsEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _savePattern(List<int> nodes) async {
    final patternService = ref.read(patternServiceProvider);
    await patternService.setPattern(nodes);

    await ref.read(appLockSettingsProvider.notifier).setEnabled(true);
    await ref
        .read(appLockSettingsProvider.notifier)
        .setMethod(AppLockMethod.pattern);

    ref.read(appLockProvider.notifier).onPatternSet();

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF0F4FF);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (_confirming) {
              setState(() {
                _confirming = false;
                _firstPattern = null;
                _lockState = PatternLockState.idle;
                _errorMessage = null;
              });
              _patternKey.currentState?.reset();
            } else {
              Navigator.of(context).pop(false);
            }
          },
        ),
        title: Text(
          widget.isChange ? 'Change Pattern' : 'Set Up Pattern',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),

                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        cs.primary.withValues(alpha: 0.2),
                        cs.primary.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.grid_view_rounded,
                      color: cs.primary, size: 34),
                ),
                const SizedBox(height: 20),

                // Title
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _confirming
                        ? 'Confirm your pattern'
                        : 'Draw your unlock pattern',
                    key: ValueKey(_confirming),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _confirming
                        ? 'Draw the same pattern again to confirm'
                        : 'Connect at least $_minNodes dots in order',
                    key: ValueKey(_confirming),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Pattern grid
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      10 * math.sin(_shakeAnim.value * 3 * math.pi),
                      0,
                    ),
                    child: child,
                  ),
                  child: PatternLockWidget(
                    key: _patternKey,
                    onPatternComplete: _onPatternComplete,
                    lockState: _lockState,
                    minNodes: _minNodes,
                    size: 280,
                  ),
                ),
                const SizedBox(height: 24),

                // Error message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _errorMessage != null
                      ? Container(
                          key: const ValueKey('error'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-error')),
                ),
                const SizedBox(height: 16),

                // Step indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(active: true),
                    const SizedBox(width: 8),
                    _StepDot(active: _confirming),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get _minNodes => kMinPatternNodes;
}

// ── Step dot ──────────────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 24 : 10,
      height: 10,
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
