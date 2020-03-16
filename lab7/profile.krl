ruleset profile {
    meta {
        use module io.picolabs.lesson_keys
        use module io.picolabs.twilio_v2 alias twilio
    }

    global {
        phoneNum = 2082018898
    }

    rule send_sms {
        select when sensor_manager send_sms 
        twilio:send_sms(phoneNum, "nothing", "Temperature violation")
    }

    rule threshold_violation {
        select when sensor_manager threshold_violation
        pre {
            temp = event:attr("temperature")
            threshold = event:attr("threshold")
            timestamp = event:attr("timestamp")
        }
        send_directive("violation in sensor manager", {"temperature": temp, "threshold": threshold, "timestamp": timestamp})
        fired {
            raise sensor_manager event "send_sms"
        }
    }
}