ruleset wovyn_base {
    meta {
      use module io.picolabs.lesson_keys
      use module io.picolabs.twilio_v2 alias twilio
          with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
      use module io.picolabs.subscription alias Subscriptions
      use module sensor_profile alias profile
        
      shares __testing
    }
    global {
      __testing = { "queries": [ { "name": "__testing" } ],
                    "events": [ { "domain": "post", "type": "test",
                                "attrs": [ "temp", "baro" ] } ] }
      temperature_threshold = 75
      phoneNum = 2082018898
      default_host = "http://localhost:8080"
      
      threshold_violation_action = defaction(url, query_map) {
        http:post(url, form=query_map)
      }
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
            "temperature": genericThing{["data", "temperature"]}[0]{["temperatureF"]},
            "timestamp": time:now()
          }
      }
    }
  
    rule find_high_temps {
        select when wovyn new_temperature_reading
        pre {
          temperature_threshold = profile:get_threshold().defaultsTo(75)
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
      foreach Subscriptions:established("Tx_role", "sensor_manager") setting (subscription)
      pre {
        temp = event:attr("temperature")
        time = event:attr("timestamp")
        query_map = {"threshold": temperature_threshold, "temperature": temp, "timestamp": time}
        url = <<#{subscription{"Tx_host"}.defaultsTo(default_host)}/sky/event/#{subscription{"Tx"}}/sensor/sensor_management/threshold_violation>>
      }
      threshold_violation_action(url, query_map)
      // twilio:send_sms(phoneNum, "nothing", "Temperature violation")
  
    }
  }