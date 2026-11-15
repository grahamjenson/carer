# Title

Carer

# Subtitle/Tag line

Stay Connected, Rest Easy

# Keywords

Carer, Diabetes, Nightscout, AndroidAPS, CGM, Blood Glucose Monitoring, Remote Monitoring, Glucose Alerts, Caregiver App, Loop Monitoring

# Reason

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


# Promotional Text

Carer is a companion for T1D caregivers providing real-time monitoring and intelligent alerts. Designed to support safe and restful nights, Carer keeps you connected, informed, and ready to act when it matters most.

# Short Description

Carer is a monitoring app for caregivers of people with diabetes, offering real-time blood glucose data, customizable alerts, and peace of mind.

# Long Description

**Carer** is a tool for caregivers who need to stay connected to loved ones living with diabetes. It integrates with Nightscout to provide a clear, easy-to-read display of real-time blood glucose data, trends, and treatments. Designed with caregivers in mind, Carer ensures you are alerted when action is needed—day or night.

With intelligent alarms, predictive alerts, customizable notifications, and a focus on nighttime monitoring, Carer helps you rest easier knowing you’ll be informed of urgent situations. Whether you’re in the same room or across town, Carer keeps you connected and in control.

Carer is built for reliability, with features like persistent display options, OLED-friendly night modes, and customizable alarms that ensure you’ll never miss what matters most.

# List of Features

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

# Primary Setup

This app has been tested with:

1. **Omnipod Dash** 
1. **Dexcom G7** 
1. **AndroidAPS** 
1. **Nightscout**

We recommend:

1. using Dexcom + Dexcom Follow alerts because this provides a good fallback alert system if Carer, Nightscout or AAPS fails. 
1. Enabling Sync of Carbs and Temp Targets in AAPS so that the Care settings works
1. Enabling plugins in Nightscout for the status icons like battery tracking

