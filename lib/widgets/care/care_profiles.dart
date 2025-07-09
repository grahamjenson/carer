import 'package:carer/nsclient/nsclient.dart';
import 'package:carer/services/settings/care_settings.dart';
import 'package:carer/services/settings/secure_settings.dart';
import 'package:carer/services/themes_service.dart';
import 'package:carer/services/toast_service.dart';
import 'package:carer/services/ui/icons.dart';
import 'package:carer/services/update_service.dart';
import 'package:carer/utils/futures.dart';
import 'package:carer/widgets/care/care_model.dart';
import 'package:carer/widgets/common/dialogs.dart';
import 'package:carer/widgets/smarttext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

typedef GetS = String Function();
typedef SetS = void Function(String);

typedef Setter = void Function(int);
typedef Getter = int Function();

class ProfileSettingsModel extends CareModel {
  final ASignal<String> nameSignal;
  final ASignal<int> durationSignal;
  final ASignal<int> percentSignal;

  ProfileSettingsModel(this.nameSignal, this.durationSignal, this.percentSignal);

  String getName() => nameSignal.value;

  void setName(String name) {
    nameSignal.value = name;
  }

  int getDuration() => durationSignal.value;
  void setDuration(int d) {
    if (d < 0) {
      d = 0;
    }
    durationSignal.value = d;
  }

  int getPercent() => percentSignal.value;
  void setPercent(int percent) {
    if (percent < 0) {
      percent = 0;
    }
    if (percent > 200) {
      percent = 200;
    }
    percentSignal.value = percent;
  }

  @override
  IconData get icon => CarerIcons.CARE_PROFILE;

  @override
  SmartText get smartText {
    var percent = getPercent();
    var duration = getDuration();
    var name = getName();

    if (duration == 0) {
      return SmartText(texts: [
        "$name\n",
        "$percent%",
      ], styles: [
        largeStyle,
        subLargeStyle,
      ]);
    }

    return SmartText(texts: [
      "$name\n",
      "$percent%",
      " for ",
      "$duration",
      "mins",
    ], styles: [
      largeStyle,
      subLargeStyle,
      subSmallStyle,
      subLargeStyle,
      subSmallStyle,
    ]);
  }

  @override
  Color get highlightColor => ColorSchemes.secondaryColor;

  @override
  String get description {
    var duration = getDuration();
    var percent = getPercent();
    var name = getName();

    if (duration == 0) {
      return "$name at $percent%";
    }
    return "$name at $percent%\nfor $duration mins";
  }

  @override
  OnPressedFunction generateOnPressedFunction(BuildContext context) {
    var duration = getDuration();
    var percent = getPercent();
    var name = getName();

    return () async {
      bool? areYouSure = await Dialogs.areYouSureDialog(context, "Confirm $description", 'Are you sure you want to $description?', "Profile Switch");

      if (areYouSure == true) {
        var (nsURL, nsToken) = SecureSettings().nightscoutURLAndToken;
        NSClient().switchProfile(nsURL, nsToken, name, duration, percent).then((value) {
          if (value) {
            ToastService().showSuccess("Profile Switch $name", description: description);
            UpdateService().nsProfileUpdater.addExternalReason("Added Profile Switch");
          } else {
            ToastService().showError("Failed to set Profile Switch");
          }
        });

        if (context.mounted) {
          GoRouter.of(context).go("/display", extra: {'from': '/care'});
        }
      }
    };
  }
}

List<ProfileSettingsModel> allProfileSwitches = [
  ProfileSettingsModel(
    CareSettings().profile1NameSignal,
    CareSettings().profile1DurationSignal,
    CareSettings().profile1PercentSignal,
  ),
  ProfileSettingsModel(
    CareSettings().profile2NameSignal,
    CareSettings().profile2DurationSignal,
    CareSettings().profile2PercentSignal,
  ),
  ProfileSettingsModel(
    CareSettings().profile3NameSignal,
    CareSettings().profile3DurationSignal,
    CareSettings().profile3PercentSignal,
  ),
  ProfileSettingsModel(
    CareSettings().profile4NameSignal,
    CareSettings().profile4DurationSignal,
    CareSettings().profile4PercentSignal,
  ),
];
