import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class OfflineBannerWrapper extends StatefulWidget {
  final Widget child;

  const OfflineBannerWrapper({super.key, required this.child});

  @override
  State<OfflineBannerWrapper> createState() => _OfflineBannerWrapperState();
}

class _OfflineBannerWrapperState extends State<OfflineBannerWrapper>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    // Check initial state
    ConnectivityService.instance.isConnected.then((online) {
      if (mounted) setState(() => _isOnline = online);
      if (!online) _controller.forward();
    });

    // Listen for changes
    ConnectivityService.instance.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizeTransition(
          sizeFactor: _animation,
          child: Container(
            width: double.infinity,
            color: const Color(0xFFB91C1C),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No internet connection – tasks will sync when online',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!_isOnline)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}