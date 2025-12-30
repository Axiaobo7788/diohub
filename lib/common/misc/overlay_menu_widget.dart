import 'package:diohub/common/animations/size_expanded_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';

class OverlayController {
  final List<void Function()> _openCallbacks = [];
  final List<void Function()> _closeCallbacks = [];
  final List<void Function()> _tappedCallbacks = [];

  void addListener({
    required void Function() open,
    required void Function() close,
    required void Function() tapped,
  }) {
    _openCallbacks.add(open);
    _closeCallbacks.add(close);
    _tappedCallbacks.add(tapped);
  }

  void removeListener({
    required void Function() open,
    required void Function() close,
    required void Function() tapped,
  }) {
    _openCallbacks.remove(open);
    _closeCallbacks.remove(close);
    _tappedCallbacks.remove(tapped);
  }

  void open() {
    for (final callback in _openCallbacks) {
      callback();
    }
  }

  void close() {
    for (final callback in _closeCallbacks) {
      callback();
    }
  }

  void tapped() {
    for (final callback in _tappedCallbacks) {
      callback();
    }
  }
}

class OverlayMenuWidget extends StatefulWidget {
  const OverlayMenuWidget({
    required this.child,
    required this.overlay,
    required this.controller,
    this.heightMultiplier = 0.7,
    this.offSet = 0,
    this.initiallyVisible = false,
    this.childAnchor = Alignment.bottomCenter,
    this.portalAnchor = Alignment.topCenter,
    super.key,
  })  : assert(heightMultiplier <= 1, 'heightMultiplier should be less than 1'),
        assert(
          (childAnchor == null) == (portalAnchor == null),
          'Either both should be none, or none of them should be.',
        );
  final Widget child;
  final Widget overlay;
  final bool initiallyVisible;
  final Alignment? childAnchor;
  final Alignment? portalAnchor;
  final double heightMultiplier;
  final OverlayController controller;
  final double offSet;

  @override
  OverlayMenuWidgetState createState() => OverlayMenuWidgetState();
}

class OverlayMenuWidgetState extends State<OverlayMenuWidget> {
  late bool visible;
  @override
  void initState() {
    super.initState();
    visible = widget.initiallyVisible;
    setupController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(
      open: openOverlay,
      close: closeOverlay,
      tapped: tapped,
    );
    super.dispose();
  }

  void setupController() {
    widget.controller.addListener(
      open: openOverlay,
      close: closeOverlay,
      tapped: tapped,
    );
  }

  void openOverlay() {
    setState(() {
      visible = true;
    });
  }

  void closeOverlay() {
    setState(() {
      visible = false;
    });
  }

  void tapped() {
    setState(() {
      visible = !visible;
    });
  }

  @override
  Widget build(final BuildContext context) {
    final Size media = MediaQuery.of(context).size;
    return PortalTarget(
      visible: visible,
      portalFollower: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            visible = false;
          });
        },
      ),
      child: PortalTarget(
        portalFollower: SizeExpandedSection(
          child: SizedBox(
            height: (media.height - widget.offSet) * widget.heightMultiplier,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: widget.childAnchor == Alignment.topCenter
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: <Widget>[
                  Flexible(child: widget.overlay),
                ],
              ),
            ),
          ),
        ),
        visible: visible,
        anchor: Aligned(
          follower: widget.portalAnchor ?? Alignment.topCenter,
          target: widget.childAnchor ?? Alignment.bottomCenter,
        ),
        child: widget.child,
      ),
    );
  }
}
