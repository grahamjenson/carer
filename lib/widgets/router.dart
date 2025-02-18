//navigatorObservers: [NavigationChangeObserver(), SentryNavigatorObserver()],

//    Widget initialRoute = const RootPage();
// if (IntroductionPage.needsOnboarding()) {
//   initialRoute = const IntroductionPage();
// }

import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/alarms/flashing_widget.dart';
import 'package:carer/widgets/alarms/snoozetime_page.dart';
import 'package:carer/widgets/bar/bar_bottom.dart';
import 'package:carer/widgets/pages/alarm_settings_page.dart';
import 'package:carer/widgets/pages/care_page.dart';
import 'package:carer/widgets/pages/display_page.dart';
import 'package:carer/widgets/pages/events_page.dart';
import 'package:carer/widgets/pages/introduction_page.dart';
import 'package:carer/widgets/pages/settingspage.dart';
import 'package:carer/widgets/settings/alarms_pages/battery_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/fast_fall_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/fast_rise_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/low_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/no_data_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/urgent_high_alarm_page.dart';
import 'package:carer/widgets/settings/alarms_pages/urgent_low_page.dart';
import 'package:carer/widgets/settings/debug_pages/debug_pages.dart';
import 'package:carer/widgets/settings/debug_pages/log_error_page.dart';
import 'package:carer/widgets/settings/debug_pages/nightscout_debug.dart';
import 'package:carer/widgets/settings/service_pages/nightscout_settings.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class OffsetPairs {
  final Offset begin;
  final Offset end;

  final Offset beginReverse;
  final Offset endReverse;

  const OffsetPairs(this.begin, this.end, this.beginReverse, this.endReverse);
}

const leftToRight = OffsetPairs(Offset(-1.0, 0.0), Offset.zero, Offset.zero, Offset(1.0, 0.0));
const rightToLeft = OffsetPairs(Offset(1.0, 0.0), Offset.zero, Offset.zero, Offset(-1.0, 0.0));
const upToDown = OffsetPairs(Offset(0.0, 1.0), Offset.zero, Offset.zero, Offset(0.0, 1.0));
const downToUp = OffsetPairs(Offset(0.0, 1.0), Offset.zero, Offset.zero, Offset(0.0, -1.0));

OffsetPairs getOffsetPairForState(GoRouterState state) {
  var to = currentRoute.value;
  var from = currentRoute.previousValue;

  if (from == null || from == "") {
    return rightToLeft;
  }

  var routeOrderFrom = routeOrder(from);
  var routeOrderTo = routeOrder(to);

  if (routeOrderFrom == routeOrderTo) {
    return rightToLeft;
  }

  if (routeOrderFrom > routeOrderTo) {
    return leftToRight;
  }

  return rightToLeft;
}

ASignal<String> currentRoute = ASignal<String>("/display", debugLabel: "CurrentRoute");
double routeOrder(String route) {
  if (route.startsWith("/display")) {
    return 0;
  }
  if (route.startsWith("/care")) {
    return 1;
  }

  if (route.startsWith("/alarms")) {
    return 2;
  }

  if (route.startsWith("/settings")) {
    return 3;
  }
  return 100;
}

CustomTransitionPage getSimpleSlideTransitionPage(
    {required BuildContext context, required GoRouterState state, required Widget child, required OffsetPairs offset}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: offset.begin,
          end: offset.end,
        ).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: offset.beginReverse,
            end: offset.endReverse,
          ).animate(secondaryAnimation),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage getPageSlideTransitionPage({required BuildContext context, required GoRouterState state, required Widget child}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return AWatch(
        (context) {
          var offset = getOffsetPairForState(state);
          return SlideTransition(
              position: Tween<Offset>(
                begin: offset.begin,
                end: offset.end,
              ).animate(animation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: offset.beginReverse,
                  end: offset.endReverse,
                ).animate(secondaryAnimation),
                child: child,
              ));
        },
        debugLabel: "PageTransitionReverse",
        dependencies: [currentRoute],
      );
    },
  );
}

pageBuilderBuilder(Widget widget) {
  return (BuildContext context, GoRouterState state) {
    return getPageSlideTransitionPage(context: context, state: state, child: widget);
  };
}

GoRouter? router;
GoRouter getRouter() {
  if (router != null) {
    return router!;
  }
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'main');

  router = GoRouter(
    observers: [NavigationChangeObserver(), SentryNavigatorObserver()],
    navigatorKey: rootNavigatorKey,
    initialLocation: "/display",
    redirect: (BuildContext context, GoRouterState state) {
      if (IntroductionPage.needsOnboarding()) {
        return '/intro';
      }
      return null;
    },
    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state, Widget child) {
          var childStack = Stack(children: [
            Scaffold(
              backgroundColor: themeMixin.backgroundColor(context),
              body: SafeArea(
                left: false,
                right: false,
                bottom: false,
                minimum: const EdgeInsets.all(0),
                child: child,
              ),
              bottomNavigationBar: const BarBottom(),
            ),
            const FlasthingWidget()
          ]);

          //final extra = state.extra; - might need this at some point

          return CustomTransitionPage(
              child: child,
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: CurveTween(curve: Curves.easeInOut).animate(animation), child: childStack);
              });
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            pageBuilder: pageBuilderBuilder(const DisplayPage()),
          ),
          GoRoute(
            path: '/display',
            pageBuilder: pageBuilderBuilder(const DisplayPage()),
          ),
          GoRoute(
            path: '/care',
            pageBuilder: pageBuilderBuilder(const CarePage()),
          ),
          GoRoute(
            path: '/alarms',
            pageBuilder: pageBuilderBuilder(const AlarmsSettingsPage()),
            routes: <RouteBase>[
              GoRoute(
                path: '/urgent_low_alarm',
                pageBuilder: pageBuilderBuilder(const UrgentAlarmLowSettingsPage()),
              ),
              GoRoute(
                path: '/low_alarm',
                pageBuilder: pageBuilderBuilder(const LowAlarmSettingsPage()),
              ),
              GoRoute(
                path: '/high_alarm',
                pageBuilder: pageBuilderBuilder(const HighAlarmSettingsPage()),
              ),
              GoRoute(
                path: '/urgent_high_alarm',
                pageBuilder: pageBuilderBuilder(const UrgentAlarmHighSettingsPage()),
              ),
              GoRoute(
                path: '/fast_rise_alarm',
                pageBuilder: pageBuilderBuilder(const FastRiseAlarmSettingsPage()),
              ),
              GoRoute(
                path: '/fast_drop_alarm',
                pageBuilder: pageBuilderBuilder(const FastFallAlarmSettingsPage()),
              ),
              GoRoute(
                path: '/no_data_alarm',
                pageBuilder: pageBuilderBuilder(const NoDataAlarmSettingsPage()),
              ),
              GoRoute(
                path: '/battery_alarm',
                pageBuilder: pageBuilderBuilder(const BatteryAlarmSettingsPage()),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: pageBuilderBuilder(const SettingsPage()),
            routes: <RouteBase>[
              GoRoute(
                path: '/nightscout',
                pageBuilder: pageBuilderBuilder(NightscoutSettingsPage()),
              ),
              GoRoute(
                path: '/debug',
                pageBuilder: pageBuilderBuilder(const DebugSettingsPage()),
                routes: <RouteBase>[
                  GoRoute(
                    path: '/log_errors',
                    builder: (BuildContext context, GoRouterState state) {
                      return const LogErrorPage();
                    },
                  ),
                  GoRoute(
                    path: '/nightscout_debug',
                    builder: (BuildContext context, GoRouterState state) {
                      return const NightScoutServiceDebugPage();
                    },
                  ),
                ],
              ),
              GoRoute(
                path: '/events',
                pageBuilder: pageBuilderBuilder(const EventsPage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/intro',
        builder: (BuildContext context, GoRouterState state) {
          return const IntroductionPage();
        },
      ),
      GoRoute(
        path: '/snooze',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return getSimpleSlideTransitionPage(
            context: context,
            state: state,
            child: const SnoozeTimePage(),
            offset: upToDown,
          );
        },
      ),
    ],
  );

  router!.routerDelegate.addListener(updateOnRouteChange);
  //router!.routeInformationProvider.addListener(updateCurrentPath);
  router!.routerDelegate.addListener(updateCurrentPath);

  return router!;
}

void updateCurrentPath() {
  currentRoute.value = router!.state.uri.toString();
}
