// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'adaptive_layout.dart';
import 'breakpoints.dart';
import 'slot_layout.dart';

/// [AdaptiveScaffold] is a Widget that handles macro changes in navigational
/// elemtents and a body/secondaryBody based on the current features of the
/// screen such as screen width and platform. For example, the navigational
/// elements would be a [BottomNavigationBar] on a small mobile device and a
/// [NavigationRail] on larger devices.
///
/// Also provides a variety of helper methods for navigational elements,
/// animations, and more.
///
/// The interior of this widget is an abstraction of [AdaptiveLayout] but easier
/// to use at the cost of being less customizable. If you feel like you are too
/// constrained by [AdaptiveScaffold] then [AdaptiveLayout] should fit all your
/// needs.
///
/// See also:
///  * [AdaptiveLayout], which is what this widget is built upon internally and
/// acts as a more customizable alternative.
///  * [SlotLayout], which handles switching and animations between elements
/// based on [Breakpoint]s.
///  * [SlotLayoutConfig], which holds information regarding Widgets and the
/// desired way to animate between switches. Often used within [SlotLayout].
///  * [Design Doc](https://flutter.dev/go/adaptive-layout-foldables).
///  * [Material Design 3 Specifications] (https://m3.material.io/foundations/adaptive-design/overview).
class AdaptiveScaffold extends StatefulWidget {
  /// Returns an [AdaptiveScaffold] by passing information down to an
  /// [AdaptiveLayout].
  const AdaptiveScaffold({
    this.destinations,
    this.selectedIndex = 0,
    this.smallBody,
    this.body,
    this.largeBody,
    this.smallSecondaryBody,
    this.secondaryBody,
    this.largeSecondaryBody,
    this.bodyRatio,
    this.smallBreakpoint = Breakpoints.small,
    this.mediumBreakpoint = Breakpoints.medium,
    this.largeBreakpoint = Breakpoints.large,
    this.drawerBreakpoint = Breakpoints.smallDesktop,
    this.internalAnimations = true,
    this.bodyOrientation = Axis.horizontal,
    this.onSelectedIndexChange,
    this.preferDrawerOnDesktop = true,
    this.appBar,
    this.navigationRailWidth = 72,
    this.extendedNavigationRailWidth = 192,
    super.key,
  });

  /// The destinations to be used in navigation items. These are converted to
  /// [NavigationRailDestination]s and [BottomNavigationBarItem]s and inserted
  /// into the appropriate places. If passing destinations, you must also pass a
  /// selected index to be used by the [NavigationRail].
  final List<NavigationDestination>? destinations;

  /// The index to be used by the [NavigationRail] if applicable.
  final int? selectedIndex;

  /// Widget to be displayed in the body slot at the smallest breakpoint.
  ///
  /// If nothing is entered for this property, then the default [body] is
  /// displayed in the slot. If null is entered for this slot, the slot stays
  /// empty.
  final WidgetBuilder? smallBody;

  /// Widget to be displayed in the body slot at the middle breakpoint.
  ///
  /// The default displayed body.
  final WidgetBuilder? body;

  /// Widget to be displayed in the body slot at the largest breakpoint.
  ///
  /// If nothing is entered for this property, then the default [body] is
  /// displayed in the slot. If null is entered for this slot, the slot stays
  /// empty.
  final WidgetBuilder? largeBody;

  /// Widget to be displayed in the secondaryBody slot at the smallest
  /// breakpoint.
  ///
  /// If nothing is entered for this property, then the default [secondaryBody]
  /// is displayed in the slot. If null is entered for this slot, the slot stays
  /// empty.
  final WidgetBuilder? smallSecondaryBody;

  /// Widget to be displayed in the secondaryBody slot at the middle breakpoint.
  ///
  /// The default displayed secondaryBody.
  final WidgetBuilder? secondaryBody;

  /// Widget to be displayed in the seconaryBody slot at the smallest
  /// breakpoint.
  ///
  /// If nothing is entered for this property, then the default [secondaryBody]
  /// is displayed in the slot. If null is entered for this slot, the slot stays
  /// empty.
  final WidgetBuilder? largeSecondaryBody;

  /// Defines the fractional ratio of body to the secondaryBody.
  ///
  /// For example 0.3 would mean body takes up 30% of the available space and
  /// secondaryBody takes up the rest.
  ///
  /// If this value is null, the ratio is defined so that the split axis is in
  /// the center of the screen.
  final double? bodyRatio;

  /// The breakpoint defined for the small size, associated with mobile-like
  /// features.
  ///
  /// Defaults to [Breakpoints.small].
  final Breakpoint smallBreakpoint;

  /// The breakpoint defined for the medium size, associated with tablet-like
  /// features.
  ///
  /// Defaults to [Breakpoints.mediumBreakpoint].
  final Breakpoint mediumBreakpoint;

  /// The breakpoint defined for the large size, associated with desktop-like
  /// features.
  ///
  /// Defaults to [Breakpoints.largeBreakpoint].
  final Breakpoint largeBreakpoint;

  /// Whether or not the developer wants the smooth entering slide transition on
  /// secondaryBody.
  ///
  /// Defaults to true.
  final bool internalAnimations;

  /// The orientation of the body and secondaryBody. Either horizontal (side by
  /// side) or vertical (top to bottom).
  ///
  /// Defaults to Axis.horizontal.
  final Axis bodyOrientation;

  /// Whether to use a [Drawer] over a [BottomNavigationBar] when not on mobile
  /// and Breakpoint is small.
  ///
  /// Defaults to true.
  final bool preferDrawerOnDesktop;

  /// Option to override the drawerBreakpoint for the usage of [Drawer] over the
  /// usual [BottomNavigationBar].
  ///
  /// Defaults to [Breakpoints.onlySmallDesktop].
  final Breakpoint drawerBreakpoint;

  /// Option to override the default [AppBar] when using drawer in desktop
  /// small.
  final AppBar? appBar;

  /// Callback function for when the index of a [NavigationRail] changes.
  final Function(int)? onSelectedIndexChange;

  /// The width used for the internal [NavigationRail] at the medium [Breakpoint].
  final double navigationRailWidth;

  /// The width used for the internal extended [NavigationRail] at the large
  /// [Breakpoint].
  final double extendedNavigationRailWidth;

  /// Callback function for when the index of a [NavigationRail] changes.
  static WidgetBuilder emptyBuilder = (_) => const SizedBox();

  /// Public helper method to be used for creating a [NavigationRail] from a
  /// list of [NavigationDestination]s. Takes in a [selectedIndex] property for
  /// the current selected item in the [NavigationRail] and [extended] for
  /// whether the [NavigationRail] is extended or not.
  static Builder toNavigationRail({
    required List<NavigationDestination> destinations,
    double width = 72,
    int selectedIndex = 0,
    bool extended = false,
    Color backgroundColor = Colors.transparent,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
    Widget? leading,
    Widget? trailing,
    Function(int)? onDestinationSelected,
    NavigationRailLabelType labelType = NavigationRailLabelType.none,
  }) {
    if (extended && width == 72) {
      width = 192;
    }
    return Builder(
      builder: (BuildContext context) {
        return Padding(
          padding: padding,
          child: SizedBox(
            width: width,
            height: MediaQuery.of(context).size.height,
            child: NavigationRail(
              onDestinationSelected: onDestinationSelected,
              labelType: labelType,
              leading: leading,
              trailing: trailing,
              backgroundColor: backgroundColor,
              extended: extended,
              selectedIndex: selectedIndex,
              destinations: <NavigationRailDestination>[
                for (NavigationDestination destination in destinations)
                  NavigationRailDestination(
                    label: Text(destination.label),
                    icon: destination.icon,
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  /// Public helper method to be used for creating a [BottomNavigationBar] from
  /// a list of [NavigationDestination]s.
  static BottomNavigationBar toBottomNavigationBar(
      {required List<NavigationDestination> destinations,
      Color selectedItemColor = Colors.black,
      Color backgroundColor = Colors.transparent}) {
    return BottomNavigationBar(
      backgroundColor: backgroundColor,
      selectedItemColor: selectedItemColor,
      items: <BottomNavigationBarItem>[
        for (NavigationDestination destination in destinations)
          BottomNavigationBarItem(
            label: destination.label,
            icon: destination.icon,
          )
      ],
    );
  }

  /// Animation from bottom offscreen up onto the screen.
  static AnimatedWidget bottomToTop(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// Animation from on the screen down off the screen.
  static AnimatedWidget topToBottom(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(0, 1),
      ).animate(animation),
      child: child,
    );
  }

  /// Animation from left off the screen into the screen.
  static AnimatedWidget leftOutIn(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// Animation from on screen to left off screen.
  static AnimatedWidget leftInOut(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1, 0),
      ).animate(animation),
      child: child,
    );
  }

  /// Animation from right off screen to on screen.
  static AnimatedWidget rightOutIn(Widget child, Animation<double> animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// Fade in animation.
  static Widget fadeIn(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInCubic),
      child: child,
    );
  }

  /// Fade out animation.
  static Widget fadeOut(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(
          parent: ReverseAnimation(animation), curve: Curves.easeInCubic),
      child: child,
    );
  }

  /// Keep widget on screen while it is leaving
  static Widget stayOnScreen(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 1.0).animate(animation),
      child: child,
    );
  }

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: widget.drawerBreakpoint.isActive(context)
            ? widget.appBar ?? AppBar()
            : null,
        drawer: widget.drawerBreakpoint.isActive(context)
            ? Drawer(
                child: NavigationRail(
                  extended: true,
                  selectedIndex: widget.selectedIndex,
                  destinations:
                      widget.destinations!.map(_toRailDestination).toList(),
                  onDestinationSelected: widget.onSelectedIndexChange,
                ),
              )
            : null,
        body: AdaptiveLayout(
          bodyOrientation: widget.bodyOrientation,
          bodyRatio: widget.bodyRatio,
          internalAnimations: widget.internalAnimations,
          primaryNavigation: widget.destinations != null &&
                  widget.selectedIndex != null
              ? SlotLayout(
                  config: <Breakpoint, SlotLayoutConfig>{
                    widget.mediumBreakpoint: SlotLayout.from(
                      key: const Key('primaryNavigation'),
                      builder: (_) => SizedBox(
                        width: widget.navigationRailWidth,
                        height: MediaQuery.of(context).size.height,
                        child: NavigationRail(
                          selectedIndex: widget.selectedIndex,
                          destinations: widget.destinations!
                              .map(_toRailDestination)
                              .toList(),
                          onDestinationSelected: widget.onSelectedIndexChange,
                        ),
                      ),
                    ),
                    widget.largeBreakpoint: SlotLayout.from(
                      key: const Key('primaryNavigation1'),
                      builder: (_) => SizedBox(
                        width: widget.extendedNavigationRailWidth,
                        height: MediaQuery.of(context).size.height,
                        child: NavigationRail(
                          extended: true,
                          selectedIndex: widget.selectedIndex,
                          destinations: widget.destinations!
                              .map(_toRailDestination)
                              .toList(),
                          onDestinationSelected: widget.onSelectedIndexChange,
                        ),
                      ),
                    ),
                  },
                )
              : null,
          bottomNavigation: widget.destinations != null &&
                  !widget.drawerBreakpoint.isActive(context)
              ? SlotLayout(
                  config: <Breakpoint, SlotLayoutConfig>{
                    widget.smallBreakpoint: SlotLayout.from(
                      key: const Key('bottomNavigation'),
                      builder: (_) => BottomNavigationBar(
                        items:
                            widget.destinations!.map(_toBottomNavItem).toList(),
                      ),
                    ),
                  },
                )
              : null,
          body: SlotLayout(
            config: <Breakpoint, SlotLayoutConfig?>{
              Breakpoints.standard: SlotLayout.from(
                key: const Key('body'),
                inAnimation: AdaptiveScaffold.fadeIn,
                outAnimation: AdaptiveScaffold.fadeOut,
                builder: widget.body,
              ),
              if (widget.smallBody != null)
                widget.smallBreakpoint:
                    (widget.smallBody != AdaptiveScaffold.emptyBuilder)
                        ? SlotLayout.from(
                            key: const Key('smallBody'),
                            inAnimation: AdaptiveScaffold.fadeIn,
                            outAnimation: AdaptiveScaffold.fadeOut,
                            builder: widget.smallBody,
                          )
                        : null,
              if (widget.body != null)
                widget.mediumBreakpoint:
                    (widget.body != AdaptiveScaffold.emptyBuilder)
                        ? SlotLayout.from(
                            key: const Key('body'),
                            inAnimation: AdaptiveScaffold.fadeIn,
                            outAnimation: AdaptiveScaffold.fadeOut,
                            builder: widget.body,
                          )
                        : null,
              if (widget.largeBody != null)
                widget.largeBreakpoint:
                    (widget.largeBody != AdaptiveScaffold.emptyBuilder)
                        ? SlotLayout.from(
                            key: const Key('largeBody'),
                            inAnimation: AdaptiveScaffold.fadeIn,
                            outAnimation: AdaptiveScaffold.fadeOut,
                            builder: widget.largeBody,
                          )
                        : null,
            },
          ),
          secondaryBody: SlotLayout(
            config: <Breakpoint, SlotLayoutConfig?>{
              Breakpoints.standard: SlotLayout.from(
                key: const Key('sBody'),
                outAnimation: AdaptiveScaffold.stayOnScreen,
                builder: widget.secondaryBody,
              ),
              if (widget.smallSecondaryBody != null)
                widget.smallBreakpoint:
                    (widget.smallSecondaryBody != AdaptiveScaffold.emptyBuilder)
                        ? SlotLayout.from(
                            key: const Key('smallSBody'),
                            outAnimation: AdaptiveScaffold.stayOnScreen,
                            builder: widget.smallSecondaryBody,
                          )
                        : null,
              if (widget.secondaryBody != null)
                widget.mediumBreakpoint:
                    (widget.secondaryBody != AdaptiveScaffold.emptyBuilder)
                        ? SlotLayout.from(
                            key: const Key('sBody'),
                            outAnimation: AdaptiveScaffold.stayOnScreen,
                            builder: widget.secondaryBody,
                          )
                        : null,
              if (widget.largeSecondaryBody != null)
                widget.largeBreakpoint:
                    (widget.largeSecondaryBody != AdaptiveScaffold.emptyBuilder)
                        ? SlotLayout.from(
                            key: const Key('largeSBody'),
                            outAnimation: AdaptiveScaffold.stayOnScreen,
                            builder: widget.largeSecondaryBody,
                          )
                        : null,
            },
          ),
        ),
      ),
    );
  }
}

NavigationRailDestination _toRailDestination(
    NavigationDestination destination) {
  return NavigationRailDestination(
    label: Text(destination.label),
    icon: destination.icon,
  );
}

BottomNavigationBarItem _toBottomNavItem(NavigationDestination destination) {
  return BottomNavigationBarItem(
    label: destination.label,
    icon: destination.icon,
  );
}
