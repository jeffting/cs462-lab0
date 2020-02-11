ruleset temperature_store {
    meta {
        shares __testing
      }
    global {
        __testing = { "queries": [ { "name": "__testing" } ],
                      "events": [ { "domain": "post", "type": "test",
                                  "attrs": [ "temp", "baro" ] } ] 
                                }
        empty_temps = []
      }
    rule collect_temperatures {
        select when wovyn new_temperature_reading
        pre {
            temperature = event:attr("temperature").klog("temperature: ")
            time = event:attr("timestamp").klog("time: ")
        }
        send_directive("attributes", {"temperature": temperature, "time": time} )
        always {
            ent:temperatures := ent:temperatures.append({"temperature": temperature, "time": time})
        }
    }

    rule collect_threshold_violations {
        select when wovyn threshold_violation
        pre {
            temperature = event:attr("temperature").klog("temperature_violation: ")
            time = event:attr("timestamp").klog("time: ")
        }
        send_directive("temperature_violation", {"temperature": temperature, "time": time} )
        always {
            ent:temperatures := ent:temperatures.append({"temperature_violation": temperature, "time": time})
        }
    }

    rule clear_tempertures {
        select when sensor reading_reset
        send_directive("Clear Temperatures")
        always {
            ent:temperatures := empty_temps
            ent:violations := empty_temps

        }
    }
}