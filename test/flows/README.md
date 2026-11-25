# UI flows

Tests of Carer as a person uses it, written as steps in the language of Nighttroop's `.bdd` tests. Each `.bdd` file here
is a flow. The same flows run with no device, and on an iPhone, an Android phone or a Mac.

```
// A carer adds carbs from the care page, after confirming, and Nightscout is sent them
INCLUDE steps/setup.steps
CLICK #bar_bottom_Care_false
CLICK text=Add 5g carbs
ASSERT_TEXT_VISIBLE Are you sure you want to 5g Carb?
CLICK text=Add Carbs
ASSERT_REQUEST POST /api/v3/treatments "eventType":"Carb Correction","carbs":5
ASSERT_TEXT_VISIBLE 5g carbs added
```

## Running them

- With no device, as part of `flutter test`, or just the flows: `flutter test test/flows/flows_test.dart`. Screenshots
  are written to `build/flows/<flow>/<name>.png`. Text that names no font, such as the care page's buttons, is drawn
  as squares there; a device draws it.
- On a device or simulator: `flutter test integration_test -d <device>`, with the device from `flutter devices`. A phone
  cannot read this folder, so after changing a flow, run `dart run tool/bundle_flows.dart`, which writes the flows
  into `integration_test/flows.g.dart`. `flutter test` fails until it is run.

Each flow starts Carer with its storage and settings empty, so it starts on the agreements page. Carer is given a fake
Nightscout, at any URL, which accepts any token, keeps what it is sent and answers with it.

## Steps

A line starting with `//` or `#` is a comment. A step that looks for something waits up to 15 seconds for it.

| Step                                     | What it does                                                                                     |
|------------------------------------------|--------------------------------------------------------------------------------------------------|
| `INCLUDE steps/setup.steps`              | Runs the steps in that file here                                                                 |
| `NIGHTSCOUT_READINGS 120 125 132`        | Nightscout has these readings, in mg/dL, the last now and each 5 minutes before the next         |
| `CLICK <target>`                         | Taps it, scrolling to it first                                                                   |
| `INPUT <target> <text>`                  | Types the text into the field                                                                    |
| `ASSERT_VISIBLE <target>`                | It is shown                                                                                      |
| `ASSERT_NOT_VISIBLE <target>`            | It is not shown                                                                                  |
| `ASSERT_TEXT_VISIBLE <text>`             | Some text that contains it is shown                                                              |
| `ASSERT_PATH /display`                   | Carer is on that page                                                                            |
| `ASSERT_REQUEST <method> <path> <text>`  | Carer sent Nightscout that request, with the text in its body                                    |
| `SCREENSHOT <name>`                      | Takes a screenshot                                                                               |

A target is `#key`, the widget with `ValueKey("key")`, or `text=Some text`, the text exactly. Give a widget a key
when its text is not enough to find it, or is not shown.

`steps/setup.steps` is a carer who has accepted the agreements and saved their Nightscout, on the display page.

## Adding a step

Steps are in `runner.dart`'s `_step`. One that waits for something uses `_waitFor` or `_waitUntil`, so it works the
same on a slow phone.
