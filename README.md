# Carer by t1dnz

I built **Carer** to reduce my anxiety around caring for our son's diabetes at night. I wanted an app that would alert me if something was wrong—but also let me sleep if everything was (or would be) fine. Sleeping through an emergency is a nightmare, but constant alarms and fatigue are just as exhausting for those managing diabetes. **Carer** is designed to wake you up when it’s truly needed, while being built for a good night’s rest.

To achieve this, **Carer** focuses on:

1. **Before Sleep Checklist**  
   Every night, I used to manually check:  
   - Are all the phones charging?  
   - Is my phone off silent?  
   - Is the volume loud enough?  
   - Do we need to change the pump or sensor tomorrow?  
   - Does the pump have enough insulin?  
   
   Now, Carer automates these checks, making it easier to fall asleep with confidence that nothing has been missed.

2. **Wake Up Gently**  
   I need to wake up when there’s an alert, but being jolted awake with a loud alarm spikes my adrenaline—and then it’s almost impossible to fall back asleep. Carer starts by increasing screen brightness and flashing the display, then plays the alert softly, with gradually increasing volume. If I catch it quickly, I can snooze it without waking the whole house.

3. **Confidence When Falling Back to Sleep**  
   Carer has built-in safeguards. If a low becomes urgent, or I accidentally snooze for too long, Carer can override the snooze and wake me up again. The display is designed to be very dim at night, so you can check it without fully waking yourself. Treatment times are displayed as "time since given," so you don't have to do math when you are half asleep to figure out if another treatment is needed.

4. **Configurable Alarms**  
   Carer gives you control over how and when alarms wake you, with customizable options that work for your routine. Predictive low alerts and smart snooze mean you only wake when it’s necessary—and sleep when it’s safe.

---

**Carer** will always be free, with no ads. I have big plans to keep improving it—for myself and for other carers of people managing with Type 1 diabetes.

# Features


1. Seamless Nightscout integration for real-time data syncing
1. Clear, customizable display optimized for quick glances and readability
1. Nighttime display mode with low brightness and OLED-friendly design
1. Graph displaying blood glucose levels, target ranges, basal rates, and past treatments
1. Treatments Table showing past actions and insulin/carb inputs
1. Customizable Statistics Table with metrics like IOB, COB, Temp Basal, Temp Target, Time In Range (TIR)
1. Customizable Status Icons for battery status, phone silence, phone battery status, pump/cannula changes, sensor changes, and more
1. Ability to log carbs and set temporary targets (requires AAPS sync setup)
1. Configurable alarms, including:  
   - Urgent Low  
   - Low (with predictive low)
   - High (with smart snooze)
   - Urgent High  
   - Fast Rise and Drop  
   - No Data  
   - Low Battery  
1. Adjustable Target Ranges for alerts
1. Snooze to temporary silence of alarms for a time
1. Non-audio alerting with screen flashing and brightness adjustments
1. Phone Volume override to never miss an alert
1. Volume progression to increase alarm volume over time to minimize disturbance
1. Snooze safety features:  
   - Automatically stops snoozing when levels are in range for 20 minutes  
   - Override snooze if a low becomes urgent  
1. Support for both mmol/L and mg/dL units
1. Keep screen active to use Carer as a nighttime display (alarms require screen to be awake)
1. Nighttime hours setting with auto-dimming to lower brightness and color intensity at night


## Alarm Music

1. From Nightguard
1. https://uppbeat.io/t/hybridas/open-spaces
1. https://uppbeat.io/t/mountaineer/lets-go


# Development

## Sentry Docs

To upload the symbols and such need `SENTRY_AUTH_TOKEN` in env and run `flutter packages pub run sentry_dart_plugin`


## setting up some debug stuff
1. ln -s /Users/<user>/Library/Containers/nz.t1d.carer/Data/Documents macosData

### Releasing The Iphone App

1. `flutter build ipa`
2. 


# TEST

```
flutter test --coverage
genhtml coverage/lcov.info -o coverage
```