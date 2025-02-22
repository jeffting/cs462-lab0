ruleset temperature_store {
    meta {
        use module sensor_profile alias profile
        shares __testing, temperatures, threshold_violations_func, inrange_temperatures_func
        provides temperatures, threshold_violations_func, inrange_temperatures_func
      }
    global {
        __testing = { "queries": [ { "name": "__testing" } ],
                      "events": [ { "domain": "post", "type": "test",
                                  "attrs": [ "temp", "baro" ] } ] 
                                }
        empty_temps = []
        
        temperatures = function() {
            ent:temperatures.defaultsTo([])
        }

        threshold_violations_func = function() {
            ent:violations
        }

        inrange_temperatures_func = function() {
            live_threshold = profile:get_threshold()
            new_temps = ent:temperatures.filter(function(a) {a["temperature"] < live_threshold})
            new_temps
        }
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
            ent:violations := ent:violations.append({"temperature": temperature, "time": time})
        }
    }

    rule clear_temperatures {
        select when sensor reading_reset
        pre {}
        send_directive("Clear Temperatures")
        always {
            ent:temperatures := empty_temps
            ent:violations := empty_temps

        }
    }
}