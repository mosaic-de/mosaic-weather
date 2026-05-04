import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows a one-time MosaicWalkthrough above [child] on first launch.
///
/// "First launch" is keyed on a SharedPreferences flag: once the user
/// finishes or skips the walkthrough we set the flag and never push it
/// again. The gate is invisible after that — it just renders [child].
class WalkthroughGate extends StatefulWidget {
  const WalkthroughGate({
    super.key,
    required this.prefsKey,
    required this.steps,
    required this.child,
  });

  final String prefsKey;
  final List<MosaicWalkthroughStep> steps;
  final Widget child;

  @override
  State<WalkthroughGate> createState() => _WalkthroughGateState();
}

class _WalkthroughGateState extends State<WalkthroughGate> {
  @override
  void initState() {
    super.initState();
    _maybeShow();
  }

  Future<void> _maybeShow() async {
    bool seen;
    try {
      final prefs = await SharedPreferences.getInstance();
      seen = prefs.getBool(widget.prefsKey) ?? false;
    } catch (_) {
      // Best-effort: if prefs fail, treat as seen to avoid loops.
      seen = true;
    }
    if (!mounted || seen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MosaicWalkthrough.show(
        context,
        steps: widget.steps,
        onComplete: _markSeen,
        onSkip: _markSeen,
      );
    });
  }

  Future<void> _markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(widget.prefsKey, true);
    } catch (_) {
      // ignore
    }
  }

  // The walkthrough pushes onto the surface stack above [child] on
  // first launch; on subsequent launches the gate is just a passthrough.
  @override
  Widget build(BuildContext context) => widget.child;
}
