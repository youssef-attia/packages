// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'breakpoints.dart';
import 'slot_layout.dart';
import 'slot_layout_config.dart';

enum _SlotIds {
  primaryNavigation,
  secondaryNavigation,
  topNavigation,
  bottomNavigation,
  body,
  secondaryBody,
}

/// [AdaptiveLayout] is dedicated to simplifying the process of developing
/// layouts for many different screen sizes. It separates the screen into
/// several sections, also referred to as "slots". The Widget defines slots for
/// the different placements of navigational elements and two slots for a body
/// and secondaryBody. All of these slots take a [SlotLayout] Widget. This class
/// works in junction with [SlotLayout] and [SlotLayoutConfig]. This class
/// handles the placement of the slots on the screen and animations regarding
/// their macromovements.
///
/// See also:
///
///  * [SlotLayout], which handles the actual switching and animations between
/// elements based on [Breakpoint]s.
///  * [SlotLayoutConfig], which holds information regarding the actual Widgets
/// and the desired way to animate between switches. Often used within
/// [SlotLayout].
///  * [Design Doc](https://flutter.dev/go/adaptive-layout-foldables).
///  * [Material Design 3 Specifications] (https://m3.material.io/foundations/adaptive-design/overview).
class AdaptiveLayout extends StatefulWidget {
  /// Creates an [AdaptiveLayout] widget.
  const AdaptiveLayout({
    this.primaryNavigation,
    this.secondaryNavigation,
    this.topNavigation,
    this.bottomNavigation,
    this.body,
    this.secondaryBody,
    this.bodyRatio,
    this.internalAnimations = true,
    this.bodyOrientation = Axis.horizontal,
    super.key,
  });

  /// The slot placed on the beginning side of the screen; meaning on the left
  /// when the textDirection is LTR and on the right when it is RTL.
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by another method.
  final SlotLayout? primaryNavigation;

  /// The slot placed on the end side of the screen; meaning on the right
  /// when the textDirection is LTR and on the left when it is RTL.
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by another method.
  final SlotLayout? secondaryNavigation;

  /// The slot placed on the top part of the screen.
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by another method.
  final SlotLayout? topNavigation;

  /// The slot placed on the bottom part of the screen.
  ///
  /// Note: if using flexibly sized Widgets like [Container], wrap the Widget in a
  /// [SizedBox] or limit its size by another method.
  final SlotLayout? bottomNavigation;

  /// The slot that fills the rest of the space in the center.
  final SlotLayout? body;

  /// A supporting slot for [body]. Has a sliding entrance animation by default.
  /// The default ratio for the split between [body] and [secondaryBody] is so
  /// that the split axis is in the center of the screen.
  final SlotLayout? secondaryBody;

  /// Defines the fractional ratio of [body] to the [secondaryBody].
  ///
  /// For example 0.3 would mean [body] takes up 30% of the available space
  /// and[secondaryBody] takes up the rest.
  ///
  /// If this value is null, the ratio is defined so that the split axis is in
  /// the center of the screen.
  final double? bodyRatio;

  /// Whether or not the developer wants the smooth entering slide transition on
  /// [secondaryBody].
  ///
  /// Defaults to true.
  final bool internalAnimations;

  /// The orientation of the body and secondaryBody. Either horizontal (side by
  /// side) or vertical (top to bottom).
  ///
  /// Defaults to Axis.horizontal.
  final Axis bodyOrientation;

  @override
  State<AdaptiveLayout> createState() => _AdaptiveLayoutState();
}

class _AdaptiveLayoutState extends State<AdaptiveLayout>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  late Map<String, SlotLayoutConfig?> chosenWidgets =
      <String, SlotLayoutConfig?>{};
  Map<String, Size?> slotSizes = <String, Size?>{};

  Map<String, ValueNotifier<Key?>> notifiers = <String, ValueNotifier<Key?>>{};

  Set<String> isAnimating = <String>{};

  @override
  void initState() {
    if (widget.internalAnimations) {
      _controller = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: this,
      )..forward();
    } else {
      _controller = AnimationController(
        duration: Duration.zero,
        vsync: this,
      );
    }

    for (final _SlotIds item in _SlotIds.values) {
      notifiers[item.name] = ValueNotifier<Key?>(null);
      notifiers[item.name]!.addListener(() {
        isAnimating.add(item.name);
        _controller.reset();
        _controller.forward();
      });
    }

    _controller.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        isAnimating.clear();
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, SlotLayout?> slots = <String, SlotLayout?>{
      _SlotIds.primaryNavigation.name: widget.primaryNavigation,
      _SlotIds.secondaryNavigation.name: widget.secondaryNavigation,
      _SlotIds.topNavigation.name: widget.topNavigation,
      _SlotIds.bottomNavigation.name: widget.bottomNavigation,
      _SlotIds.body.name: widget.body,
      _SlotIds.secondaryBody.name: widget.secondaryBody,
    };
    chosenWidgets = <String, SlotLayoutConfig?>{};

    slots.forEach((String key, SlotLayout? value) {
      slots.update(
        key,
        (SlotLayout? val) => val,
        ifAbsent: () => value,
      );
      chosenWidgets.update(
        key,
        (SlotLayoutConfig? val) => val,
        ifAbsent: () => SlotLayout.pickWidget(
            context, value?.config ?? <Breakpoint, SlotLayoutConfig?>{}),
      );
    });
    final List<Widget> entries = slots.entries
        .map((MapEntry<String, SlotLayout?> entry) {
          if (entry.value != null) {
            return LayoutId(
                id: entry.key, child: entry.value ?? const SizedBox());
          }
        })
        .whereType<Widget>()
        .toList();

    notifiers.forEach((String key, ValueNotifier<Key?> notifier) {
      notifier.value = chosenWidgets[key]?.key;
    });

    Rect? hinge;
    for (final DisplayFeature e in MediaQuery.of(context).displayFeatures) {
      if (e.type == DisplayFeatureType.hinge ||
          e.type == DisplayFeatureType.fold) {
        if (e.bounds.left != 0) {
          hinge = e.bounds;
        }
      }
    }

    return CustomMultiChildLayout(
      delegate: _AdaptiveLayoutDelegate(
        slots: slots,
        chosenWidgets: chosenWidgets,
        slotSizes: slotSizes,
        controller: _controller,
        bodyRatio: widget.bodyRatio,
        isAnimating: isAnimating,
        internalAnimations: widget.internalAnimations,
        bodyOrientation: widget.bodyOrientation,
        textDirection: Directionality.of(context) == TextDirection.ltr,
        hinge: hinge,
      ),
      children: entries,
    );
  }
}

/// The delegate responsible for laying out the slots in their correct positions.
class _AdaptiveLayoutDelegate extends MultiChildLayoutDelegate {
  _AdaptiveLayoutDelegate({
    required this.slots,
    required this.chosenWidgets,
    required this.slotSizes,
    required this.controller,
    required this.bodyRatio,
    required this.isAnimating,
    required this.internalAnimations,
    required this.bodyOrientation,
    required this.textDirection,
    this.hinge,
  }) : super(relayout: controller);

  final Map<String, SlotLayout?> slots;
  final Map<String, SlotLayoutConfig?> chosenWidgets;
  final Map<String, Size?> slotSizes;
  final Set<String> isAnimating;
  final AnimationController controller;
  final double? bodyRatio;
  final bool internalAnimations;
  final Axis bodyOrientation;
  final bool textDirection;
  final Rect? hinge;

  @override
  void performLayout(Size size) {
    double leftMargin = 0;
    double topMargin = 0;
    double rightMargin = 0;
    double bottomMargin = 0;

    // An animation that is used as either a width or height value on the Size for the body/secondaryBody.
    double animatedSize(double begin, double end) {
      if (isAnimating.contains(_SlotIds.secondaryBody.name)) {
        return internalAnimations
            ? Tween<double>(begin: begin, end: end)
                .animate(CurvedAnimation(
                    parent: controller, curve: Curves.easeInOutCubic))
                .value
            : end;
      }
      return end;
    }

    if (hasChild(_SlotIds.topNavigation.name)) {
      final Size childSize =
          layoutChild(_SlotIds.topNavigation.name, BoxConstraints.loose(size));
      // Trigger the animation if the new size is different from the old size.
      updateSize(_SlotIds.topNavigation.name, childSize);
      // Tween not the actual size, but the size that is used in the margins so the offsets can be animated.
      final Size currentSize = Tween<Size>(
              begin: slotSizes[_SlotIds.topNavigation.name] ?? Size.zero,
              end: childSize)
          .animate(controller)
          .value;
      positionChild(_SlotIds.topNavigation.name, Offset.zero);
      topMargin += currentSize.height;
    }
    if (hasChild(_SlotIds.bottomNavigation.name)) {
      final Size childSize = layoutChild(
          _SlotIds.bottomNavigation.name, BoxConstraints.loose(size));
      updateSize(_SlotIds.bottomNavigation.name, childSize);
      final Size currentSize = Tween<Size>(
              begin: slotSizes[_SlotIds.bottomNavigation.name] ?? Size.zero,
              end: childSize)
          .animate(controller)
          .value;
      positionChild(_SlotIds.bottomNavigation.name,
          Offset(0, size.height - currentSize.height));
      bottomMargin += currentSize.height;
    }
    if (hasChild(_SlotIds.primaryNavigation.name)) {
      final Size childSize = layoutChild(
          _SlotIds.primaryNavigation.name, BoxConstraints.loose(size));
      updateSize(_SlotIds.primaryNavigation.name, childSize);
      final Size currentSize = Tween<Size>(
              begin: slotSizes[_SlotIds.primaryNavigation.name] ?? Size.zero,
              end: childSize)
          .animate(controller)
          .value;
      if (textDirection) {
        positionChild(
            _SlotIds.primaryNavigation.name, Offset(leftMargin, topMargin));
        leftMargin += currentSize.width;
      } else {
        positionChild(_SlotIds.primaryNavigation.name,
            Offset(size.width - currentSize.width, topMargin));
        rightMargin += currentSize.width;
      }
    }
    if (hasChild(_SlotIds.secondaryNavigation.name)) {
      final Size childSize = layoutChild(
          _SlotIds.secondaryNavigation.name, BoxConstraints.loose(size));
      updateSize(_SlotIds.secondaryNavigation.name, childSize);
      final Size currentSize = Tween<Size>(
              begin: slotSizes[_SlotIds.secondaryNavigation.name] ?? Size.zero,
              end: childSize)
          .animate(controller)
          .value;
      if (textDirection) {
        positionChild(_SlotIds.secondaryNavigation.name,
            Offset(size.width - currentSize.width, topMargin));
        rightMargin += currentSize.width;
      } else {
        positionChild(_SlotIds.secondaryNavigation.name, Offset(0, topMargin));
        leftMargin += currentSize.width;
      }
    }

    final double remainingWidth = size.width - rightMargin - leftMargin;
    final double remainingHeight = size.height - bottomMargin - topMargin;
    final double halfWidth = size.width / 2;
    final double halfHeight = size.height / 2;
    final double hingeWidth = hinge != null ? hinge!.right - hinge!.left : 0;

    if (hasChild(_SlotIds.body.name) && hasChild(_SlotIds.secondaryBody.name)) {
      Size currentBodySize = Size.zero;
      Size currentSBodySize = Size.zero;
      if (chosenWidgets[_SlotIds.secondaryBody.name] == null ||
          chosenWidgets[_SlotIds.secondaryBody.name]!.builder == null) {
        if (!textDirection) {
          currentBodySize = layoutChild(_SlotIds.body.name,
              BoxConstraints.tight(Size(remainingWidth, remainingHeight)));
        } else if (bodyOrientation == Axis.horizontal) {
          double beginWidth;
          if (bodyRatio == null) {
            beginWidth = halfWidth - leftMargin;
          } else {
            beginWidth = remainingWidth * bodyRatio!;
          }
          currentBodySize = layoutChild(
              _SlotIds.body.name,
              BoxConstraints.tight(Size(
                  animatedSize(beginWidth, remainingWidth), remainingHeight)));
        } else {
          double beginHeight;
          if (bodyRatio == null) {
            beginHeight = halfHeight - topMargin;
          } else {
            beginHeight = remainingHeight * bodyRatio!;
          }
          currentBodySize = layoutChild(
              _SlotIds.body.name,
              BoxConstraints.tight(Size(
                  remainingWidth, animatedSize(beginHeight, remainingHeight))));
        }
        layoutChild(_SlotIds.secondaryBody.name, BoxConstraints.loose(size));
      } else {
        if (bodyOrientation == Axis.horizontal) {
          // Take this path if the body and secondaryBody are laid out horizontally.
          if (textDirection) {
            // Take this path if the textDirection is LTR.
            double finalBodySize;
            double finalSBodySize;
            if (hinge != null) {
              finalBodySize = hinge!.left - leftMargin;
              finalSBodySize =
                  size.width - (hinge!.left + hingeWidth) - rightMargin;
            } else if (bodyRatio != null) {
              finalBodySize = remainingWidth * bodyRatio!;
              finalSBodySize = remainingWidth * (1 - bodyRatio!);
            } else {
              finalBodySize = halfWidth - leftMargin;
              finalSBodySize = halfWidth - rightMargin;
            }

            currentBodySize = layoutChild(
                _SlotIds.body.name,
                BoxConstraints.tight(Size(
                    animatedSize(remainingWidth, finalBodySize),
                    remainingHeight)));
            layoutChild(_SlotIds.secondaryBody.name,
                BoxConstraints.tight(Size(finalSBodySize, remainingHeight)));
          } else {
            // Take this path if the textDirection is RTL.
            double finalBodySize;
            double finalSBodySize;
            if (hinge != null) {
              finalBodySize =
                  size.width - (hinge!.left + hingeWidth) - rightMargin;
              finalSBodySize = hinge!.left - leftMargin;
            } else if (bodyRatio != null) {
              finalBodySize = remainingWidth * bodyRatio!;
              finalSBodySize = remainingWidth * (1 - bodyRatio!);
            } else {
              finalBodySize = halfWidth - rightMargin;
              finalSBodySize = halfWidth - leftMargin;
            }
            currentSBodySize = layoutChild(
                _SlotIds.secondaryBody.name,
                BoxConstraints.tight(
                    Size(animatedSize(0, finalSBodySize), remainingHeight)));
            layoutChild(_SlotIds.body.name,
                BoxConstraints.tight(Size(finalBodySize, remainingHeight)));
          }
        } else {
          // Take this path if the body and secondaryBody are laid out vertically.
          currentBodySize = layoutChild(
            _SlotIds.body.name,
            BoxConstraints.tight(
              Size(
                remainingWidth,
                animatedSize(
                  remainingHeight,
                  bodyRatio == null
                      ? halfHeight - topMargin
                      : remainingHeight * bodyRatio!,
                ),
              ),
            ),
          );
          layoutChild(
            _SlotIds.secondaryBody.name,
            BoxConstraints.tight(
              Size(
                remainingWidth,
                bodyRatio == null
                    ? halfHeight - bottomMargin
                    : remainingHeight * (1 - bodyRatio!),
              ),
            ),
          );
        }
      }
      // Handle positioning for the body and secondaryBody.
      if (bodyOrientation == Axis.horizontal &&
          !textDirection &&
          chosenWidgets[_SlotIds.secondaryBody.name] != null) {
        if (hinge != null) {
          positionChild(
              _SlotIds.body.name,
              Offset(
                  currentSBodySize.width + leftMargin + hingeWidth, topMargin));
          positionChild(
              _SlotIds.secondaryBody.name, Offset(leftMargin, topMargin));
        } else {
          positionChild(_SlotIds.body.name,
              Offset(currentSBodySize.width + leftMargin, topMargin));
          positionChild(
              _SlotIds.secondaryBody.name, Offset(leftMargin, topMargin));
        }
      } else {
        positionChild(_SlotIds.body.name, Offset(leftMargin, topMargin));
        if (bodyOrientation == Axis.horizontal) {
          if (hinge != null) {
            positionChild(
                _SlotIds.secondaryBody.name,
                Offset(currentBodySize.width + leftMargin + hingeWidth,
                    topMargin));
          } else {
            positionChild(_SlotIds.secondaryBody.name,
                Offset(currentBodySize.width + leftMargin, topMargin));
          }
        } else {
          positionChild(_SlotIds.secondaryBody.name,
              Offset(leftMargin, topMargin + currentBodySize.height));
        }
      }
    } else if (hasChild(_SlotIds.body.name)) {
      layoutChild(_SlotIds.body.name,
          BoxConstraints.tight(Size(remainingWidth, remainingHeight)));
      positionChild(_SlotIds.body.name, Offset(leftMargin, topMargin));
    } else if (hasChild(_SlotIds.secondaryBody.name)) {
      layoutChild(_SlotIds.secondaryBody.name,
          BoxConstraints.tight(Size(remainingWidth, remainingHeight)));
    }
  }

  void updateSize(String id, Size childSize) {
    if (slotSizes[id] == null || slotSizes[id] != childSize) {
      void listener(AnimationStatus status) {
        if ((status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) &&
            (slotSizes[id] == null || slotSizes[id] != childSize)) {
          slotSizes[id] = childSize;
        }
        controller.removeStatusListener(listener);
      }

      controller.addStatusListener(listener);
    }
  }

  @override
  bool shouldRelayout(_AdaptiveLayoutDelegate oldDelegate) {
    return oldDelegate.slots != slots;
  }
}
