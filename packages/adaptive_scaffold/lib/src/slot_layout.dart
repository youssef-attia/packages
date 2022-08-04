// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

/// A Widget that takes a mapping of [SlotLayoutConfig]s to [Breakpoint]s and
/// adds the appropriate Widget based on the current screen size.
///
/// See also:
/// * [AdaptiveLayout], where [SlotLayout]s are assigned to placements on the
/// screen called "slots".
class SlotLayout extends StatefulWidget {
  /// Creates a [SlotLayout] widget.
  const SlotLayout({required this.config, super.key});

  /// Given a context and a config, it returns the [SlotLayoutConfig] that will
  /// be chosen from the config under the context's conditions.
  static SlotLayoutConfig? pickWidget(
      BuildContext context, Map<Breakpoint, SlotLayoutConfig?> config) {
    SlotLayoutConfig? chosenWidget;
    config.forEach((Breakpoint breakpoint, SlotLayoutConfig? pickedWidget) {
      if (breakpoint.isActive(context)) {
        chosenWidget = pickedWidget;
      }
    });
    return chosenWidget;
  }

  /// Maps [Breakpoint]s to [SlotLayoutConfig]s to determine what Widget to
  /// display on which condition of screens.
  ///
  /// The [SlotLayoutConfig]s in this map are nullable since some breakpoints
  /// apply to more open ranges and the nullability allows one to override the
  /// value at that Breakpoint to be null.
  ///
  /// [SlotLayout] picks the last [SlotLayoutConfig] whose corresponding
  /// [Breakpoint.isActive] returns true.
  ///
  /// If two [Breakpoint]s are active concurrently then the latter one defined
  /// in the map takes priority.
  final Map<Breakpoint, SlotLayoutConfig?> config;

  /// Acts as a delegate to the abstract class [SlotLayoutConfig].
  /// It first takes a builder which returnsd the child Widget that [SlotLayout]
  /// eventually displays with an animation.
  ///
  /// It also takes an inAnimation and outAnimation to describe how the Widget
  /// should be animated as it is switched in or out from [SlotLayout]. These
  /// are both defined as functions that takes a [Widget] and an [Animation] and
  /// return a [Widget]. These functions are passed to the [AnimatedSwitcher]
  /// inside [SlotLayout] and are to be played when the child enters/exits.
  ///
  /// Last, it takes a required key. The key should be kept constant but unique
  /// as this key is what is used to let the [SlotLayout] know that a change has
  /// been made to its child.
  ///
  /// Note that if you define a given animation phase, there may be multiple
  /// widgets being displayed depending on the phases you have chosen to animate.
  /// If you are using GlobalKeys, this may cause issues with the
  /// [AnimatedSwitcher].
  ///
  /// See also:
  ///
  ///  * [AnimatedWidget] and [ImplicitlyAnimatedWidget], which are commonly used
  /// as the returned widget for the inAnimation and outAnimation functions.
  ///  * [AnimatedSwitcher.defaultTransitionBuilder], which is what takes the
  /// inAnimation and outAnimation.
  static _SlotLayoutConfig Function({
    WidgetBuilder? builder,
    Widget Function(Widget, Animation<double>)? inAnimation,
    Widget Function(Widget, Animation<double>)? outAnimation,
    required Key key,
  }) from = ({
    WidgetBuilder? builder,
    Widget Function(Widget, Animation<double>)? inAnimation,
    Widget Function(Widget, Animation<double>)? outAnimation,
    required Key key,
  }) =>
      _SlotLayoutConfig(
        builder: builder,
        inAnimation: inAnimation,
        outAnimation: outAnimation,
        key: key,
      );

  @override
  State<SlotLayout> createState() => _SlotLayoutState();
}

class _SlotLayoutState extends State<SlotLayout>
    with SingleTickerProviderStateMixin {
  SlotLayoutConfig? chosenWidget;

  @override
  Widget build(BuildContext context) {
    chosenWidget = SlotLayout.pickWidget(context, widget.config);
    bool hasAnimation = false;
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000),
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          final Stack elements = Stack(
            children: <Widget>[
              if (hasAnimation) ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
          return elements;
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final SlotLayoutConfig configChild = child as SlotLayoutConfig;
          if (child.key == chosenWidget?.key) {
            return (configChild.inAnimation != null)
                ? child.inAnimation!(child, animation)
                : child;
          } else {
            if (configChild.outAnimation != null) {
              hasAnimation = true;
            }
            return (configChild.outAnimation != null)
                ? child.outAnimation!(child, ReverseAnimation(animation))
                : child;
          }
        },
        child: chosenWidget ?? SlotLayoutConfig.empty());
  }
}

/// Defines how [SlotLayout] should display under a certain [Breakpoint].
abstract class SlotLayoutConfig extends StatefulWidget {
  /// Creates a new [SlotLayoutConfig].
  ///
  /// Returns the child widget as is but holds properties to be accessed by other
  /// classes.
  const SlotLayoutConfig(
      {required this.builder, this.inAnimation, this.outAnimation, super.key});

  /// The child Widget that [SlotLayout] eventually returns with an animation.
  final WidgetBuilder? builder;

  /// A function that takes a [Widget] and an [Animation] and returns a [Widget].
  /// This function is passed to the [AnimatedSwitcher] inside [SlotLayout] and
  /// is to be played when the child enters.
  ///
  /// See also:
  ///
  ///  * [AnimatedWidget] and [ImplicitlyAnimatedWidget], which are commonly used
  ///  as the returned widget.
  final Widget Function(Widget, Animation<double>)? inAnimation;

  /// A function that takes a [Widget] and an [Animation] and returns a [Widget].
  /// This function is passed to the [AnimatedSwitcher] inside [SlotLayout] and
  /// is to be played when the child exits.
  ///
  /// See also:
  ///
  ///  * [AnimatedWidget] and [ImplicitlyAnimatedWidget], which are commonly used
  ///  as the returned widget.
  final Widget Function(Widget, Animation<double>)? outAnimation;

  /// An empty [SlotLayoutConfig] to be placed in a slot to indicate that the slot
  /// should show nothing.
  static SlotLayoutConfig empty() {
    return const _SlotLayoutConfig(key: Key(''), builder: null);
  }

  @override
  State<SlotLayoutConfig> createState() => _SlotLayoutConfigState();
}

class _SlotLayoutConfig extends SlotLayoutConfig {
  const _SlotLayoutConfig({
    required super.builder,
    super.inAnimation,
    super.outAnimation,
    required super.key,
  });
}

class _SlotLayoutConfigState extends State<SlotLayoutConfig> {
  @override
  Widget build(BuildContext context) {
    return (widget.builder != null)
        ? widget.builder!(context)
        : const SizedBox.shrink();
  }
}
