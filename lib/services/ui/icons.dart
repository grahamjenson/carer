// ignore_for_file: constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:unicons/unicons.dart';

// THIS FILE EXISTS TO ENSURE CONSISTENCY ACROSS THE APP OF ICON USE

class CarerIcons {
  // BAR
  static const IconData BAR_DISPLAY = CupertinoIcons.home;
  static const IconData BAR_CARE = CupertinoIcons.hand_raised;
  static const IconData BAR_SETTINGS = CupertinoIcons.settings;
  static const IconData BAR_ALARMS = CupertinoIcons.alarm;
  static const IconData BAR_INFO = CupertinoIcons.info;
  static const IconData BAR_SNOOZE = CupertinoIcons.moon_zzz;

  // CARE
  static const IconData CARE_CARBS = UniconsLine.restaurant;
  static const IconData CARE_TEMP_TARGET = UniconsLine.focus_target;
  static const IconData CARE_PROFILE = UniconsLine.user;

  // INFO
  static const IconData INFO_INSULIN_ON_BOARD = UniconsLine.syringe;
  static const IconData INFO_CARBS_ON_BOARD = UniconsLine.restaurant;
  static const IconData INFO_BASAL_RATE = UniconsLine.tear;
  static const IconData INFO_TARGET = UniconsLine.focus_target;
  static const IconData INFO_PROFILE = UniconsLine.user;
  static const IconData INFO_TODAY_IN_RANGE = UniconsLine.chart_pie;
  static const IconData INFO_YESTERDAY_IN_RANGE = UniconsLine.chart_pie_alt;

  // STATUS
  static const IconData STATUS_CANNULA_CHANGE = UniconsLine.mobile_android;
  static const IconData STATUS_SENSOR_CHANGE = UniconsLine.processor;
  static const IconData STATUS_NOT_CHARGING = UniconsLine.bolt_slash;
  static const IconData STATUS_BATTERY_LOW = UniconsLine.battery_empty;
  static const IconData STATUS_SILENT_MODE = UniconsLine.bell_slash;
  static const IconData STATUS_LOW_RESERVOIR = UniconsLine.water_drop_slash;
  static const IconData STATUS_DISABLED_ALARMS = UniconsLine.bell_slash;
  static const IconData STATUS_DISABLED_AUDIO_ALARMS = UniconsLine.volume_mute;
  static const IconData STATUS_SCREEN_CAN_SLEEP = UniconsLine.lock_slash;

  // ALARMS
  static const IconData ALARM_URGENT_HIGH = UniconsLine.temperature_plus;
  static const IconData ALARM_HIGH = UniconsLine.temperature;
  static const IconData ALARM_LOW = UniconsLine.temperature_empty;
  static const IconData ALARM_URGENT_LOW = UniconsLine.temperature_minus;
  static const IconData ALARM_FAST_DROP = UniconsLine.angle_double_down;
  static const IconData ALARM_FAST_RISE = UniconsLine.angle_double_up;
  static const IconData ALARM_NO_DATA = UniconsLine.x;
  static const IconData ALARM_LOW_BATTERY = UniconsLine.battery_empty;
  static const IconData ALARM_UNKNOWN = UniconsLine.question_circle;
  static const IconData ALARM_TEST = UniconsLine.bell;

  // EVENTS
  static const IconData EVENT_APP_RESUMED = CupertinoIcons.play;
  static const IconData EVENT_APP_PAUSED = CupertinoIcons.pause;
  static const IconData EVENT_SNOOZE = CupertinoIcons.zzz;
  static const IconData EVENT_BOLUS = UniconsLine.syringe;
  static const IconData EVENT_CARBS = UniconsLine.restaurant;

  // SETTINGS
  static const IconData SETTINGS_TERMS_OF_SERVICE = UniconsLine.document_info;
  static const IconData SETTINGS_PRIVACY_POLICY = UniconsLine.document_info;
  static const IconData SETTINGS_ABOUT = UniconsLine.info_circle;
  static const IconData SETTINGS_CONTACT = UniconsLine.envelope;
  static const IconData SETTINGS_DEBUG = UniconsLine.share;
  static const IconData SETTINGS_PLUS = UniconsLine.plus;
  static const IconData SETTINGS_MINUS = UniconsLine.minus;
  static const IconData SETTINGS_VOLUME_DOWN = UniconsLine.volume_down;
  static const IconData SETTINGS_VOLUME_UP = UniconsLine.volume_up;
  static const IconData SETTINGS_RANGE_ICON = UniconsLine.slider_h_range;
}
