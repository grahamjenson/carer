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

GoRouter getRouter() {
  final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'main');

  var router = GoRouter(
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
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return Stack(children: [
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
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              return const DisplayPage();
            },
          ),
          GoRoute(
            path: '/display',
            builder: (BuildContext context, GoRouterState state) {
              return const DisplayPage();
            },
          ),
          GoRoute(
            path: '/care',
            builder: (BuildContext context, GoRouterState state) {
              return const CarePage();
            },
          ),
          GoRoute(
            path: '/alarms',
            builder: (BuildContext context, GoRouterState state) {
              return const AlarmsSettingsPage();
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
            builder: (BuildContext context, GoRouterState state) {
              return const SettingsPage();
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
        builder: (BuildContext context, GoRouterState state) {
          return const SnoozeTimePage();
        },
      ),
    ],
  );

  router.routerDelegate.addListener(updateOnRouteChange);

  return router;
}
