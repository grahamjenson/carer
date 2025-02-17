//navigatorObservers: [NavigationChangeObserver(), SentryNavigatorObserver()],

//    Widget initialRoute = const RootPage();
// if (IntroductionPage.needsOnboarding()) {
//   initialRoute = const IntroductionPage();
// }

import 'package:carer/services/app_lifecycle_service.dart';
import 'package:carer/services/themes_service.dart';
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

CustomTransitionPage getUpDownSlideTransitionPage({required BuildContext context, required GoRouterState state, required Widget child}) {
  return CustomTransitionPage(
    child: child,
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0.0, 1.0),
          ).animate(secondaryAnimation),
          child: child,
        ),
      );
    },
  );
}

CustomTransitionPage getSideSideSlideTransitionPage({required BuildContext context, required GoRouterState state, required Widget child}) {
  var str = state.uri.toString();

  print("AAAA $str");
  var x = state.extra;
  print("BBBB $x");
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(.7, 0.0),
          end: Offset.zero,
        ).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.0),
            end: const Offset(-0.7, 0.0),
          ).animate(secondaryAnimation),
          child: child,
        ),
      );
    },
  );
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
          print("ALSO HERERE");
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
            pageBuilder: (BuildContext context, GoRouterState state) {
              return getSideSideSlideTransitionPage(context: context, state: state, child: const DisplayPage());
            },
          ),
          GoRoute(
            path: '/display',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return getSideSideSlideTransitionPage(context: context, state: state, child: const DisplayPage());
            },
          ),
          GoRoute(
            path: '/care',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return getSideSideSlideTransitionPage(context: context, state: state, child: const CarePage());
            },
          ),
          GoRoute(
            path: '/alarms',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return getSideSideSlideTransitionPage(context: context, state: state, child: const AlarmsSettingsPage());
            },
            routes: <RouteBase>[
              GoRoute(
                path: '/urgent_low_alarm',
                builder: (BuildContext context, GoRouterState state) {
                  return const UrgentAlarmLowSettingsPage();
                },
              ),
              GoRoute(
                path: '/low_alarm',
                builder: (BuildContext context, GoRouterState state) {
                  return const LowAlarmSettingsPage();
                },
              ),
              GoRoute(
                path: '/high_alarm',
                builder: (BuildContext context, GoRouterState state) {
                  return const HighAlarmSettingsPage();
                },
              ),
              GoRoute(
                path: '/urgent_high_alarm',
                builder: (BuildContext context, GoRouterState state) {
                  return const UrgentAlarmHighSettingsPage();
                },
              ),
              GoRoute(
                path: '/fast_rise_alarm',
                builder: (BuildContext context, GoRouterState state) {
                  return const FastRiseAlarmSettingsPage();
                },
              ),
              GoRoute(
                path: '/fast_drop_alarm',
                builder: (BuildContext context, GoRouterState state) {
                  return const FastFallAlarmSettingsPage();
                },
              ),
              GoRoute(
                path: '/no_data_alarm',
                builder: (BuildContext context, GoRouterState state) {
                  return const NoDataAlarmSettingsPage();
                },
              ),
              GoRoute(
                path: '/battery_alarm',
                builder: (BuildContext context, GoRouterState state) {
                  return const BatteryAlarmSettingsPage();
                },
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return getSideSideSlideTransitionPage(context: context, state: state, child: const SettingsPage());
            },
            routes: <RouteBase>[
              GoRoute(
                path: '/nightscout',
                builder: (BuildContext context, GoRouterState state) {
                  return NightscoutSettingsPage();
                },
              ),
              GoRoute(
                path: '/debug',
                builder: (BuildContext context, GoRouterState state) {
                  return const DebugSettingsPage();
                },
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
                builder: (BuildContext context, GoRouterState state) {
                  return const EventsPage();
                },
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
          return getUpDownSlideTransitionPage(
            context: context,
            state: state,
            child: const SnoozeTimePage(),
          );
        },
      ),
    ],
  );

  router!.routerDelegate.addListener(updateOnRouteChange);

  return router!;
}
