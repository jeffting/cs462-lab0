ruleset wovyn_base {
  meta {
    use module io.picolabs.lesson_keys
    use module io.picolabs.twilio_v2 alias twilio
    use module sensor_profile alias profile
      with account_sid = keys:twilio{"account_sid"}
           auth_token =  keys:twilio{"auth_token"}
    shares __testing
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "post", "type": "test",
                              "attrs": [ "temp", "baro" ] } ] }
    temperature_threshold = 75
    phoneNum = 2082018898
    default_host = "localhost:8080"
  }
 
  rule wovyn_base {
    select when wovyn heartbeat
    pre {
      genericThing = event:attr("genericThing")
    }
    if genericThing then 
    every {
      send_directive("wovyn", {"genericThing": genericThing})
    }
    fired {
      raise wovyn event "new_temperature_reading"
        attributes {
          "temperature": genericThing{["data", "temperature"]}[0]{["temperatureF"]}.klog("TEMPPPPP"),
          "timestamp": time:now()
        }
    }
  }

  rule find_high_temps {
      select when wovyn new_temperature_reading
      pre {
        temperature_threshold = profile:get_threshold()
        temperature = event:attr("temperature")
        timeStamp = event:attr("timestamp")
        violation = temperature > temperature_threshold => "Violation!!" | "No Violation!!!"

      }
      send_directive(violation);
      fired {
        raise wovyn event "threshold_violation" 
        attributes {
          "temperature": temperature,
          "timestamp": time:now()
        } if temperature > temperature_threshold
      }
  }
  
  rule threshold_notification {
    select when wovyn threshold_violation
    foreach Subscriptions:established("Tx_role", "sensor") setting (subscription)
    pre {
      temp = event:attr("temperature")
      time = event:attr("timestamp")
    }
    twilio:send_sms(phoneNum, "nothing", "Temperature violation")
    always{
      raise sensor_manager event "threshold_violation" attributes
          {   "timestamp" : timestamp,
              "temperature": temp,
              "threshold": temperature_threshold,
              "channel_type": "subscription",
              "wellKnown_Tx" : subscription{"Rx"},
              "Tx_host": subscrition{"Tx_host"}.defaultsTo(default_host)
          }
  }
  }
}