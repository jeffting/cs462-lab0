ruleset manage_sensors {
  meta {
      shares __testing, sensors, get_temps_func
      use module io.picolabs.subscription alias Subscriptions
  }
  global {
      __testing = { "events":  [ { "domain": "sensor", "type": "new_sensor", "attrs": [ "sensor_id" ] }, {"domain": "collection", "type": "empty", "attrs": []} ] }

    sensors = function() {
      Subscriptions:established("Tx_role","sensor")
    }
    
    get_temps_func = function() {
      temps = Subscriptions:established("Tx_role", "sensor").map(function(obj) {
        host = obj{"Tx_host"}.defaultsTo("http://localhost:8080")
        // host = "http://localhost:8080/"
        http:get(host + "/sky/cloud/" + obj{"Tx"} + "/temperature_store/temperatures"){"content"}.decode()
      })
      temps
    }
  }

  rule new_sensor {
      select when sensor new_sensor
      pre {
          sensor_id = event:attr("sensor_id")
          exists = ent:sensors >< sensor_id
      }
      if exists then
          send_directive("sensor exists", { "sensor_id": sensor_id})
      notfired {
        raise wrangler event "child_creation"
          attributes { "name": sensor_id, "color": "#ffff00", "child_type": "sensor", "rids": ["temperature_store", "wovyn_base", "sensor_profile"] }
      }
  }

  rule store_new_section {
      select when wrangler child_initialized
      pre {
          the_section = {"id": event:attr("id"), "eci": event:attr("eci")}
          sensor_id = event:attr("name")
          child_type = event:attr("child_type")
      }
      if sensor_id
      then
          event:send(
            { "eci": the_section{"eci"}, "eid": "update-profile",
              "domain": "sensor", "type": "profile_updated",
              "attrs": { "name": "Bobby Child", "threshold": 60, "number": 2082018898 } } )
      fired {
          ent:sensors := ent:sensors.defaultsTo({});
          ent:sensors{[sensor_id]} := the_section
          raise wrangler event "subscription" attributes
            { "name" : sensor_id,
              "Rx_role": "manager",
              "Tx_role": "sensor",
              "channel_type": "subscription",
              "wellKnown_Tx" : the_section{"eci"}
            }
      }
  }
  
  rule update_profile {
    select when sensor update_profile
    pre {
      eci = event:attr("eci")
    }
    event:send(
      { "eci": eci, "eid": "update-profile",
        "domain": "sensor", "type": "profile_update",
        "attrs": { "name": "Bobby Child", "threshold": 60, "number": 2082018898 } } )
  }
  
  rule unneeded_sensor {
    select when sensor unneeded_sensor
    pre {
      sensor_id = event:attr("sensor_id")
      exists = ent:sensors >< sensor_id
    }
    if exists then
      send_directive("deleting_section", {"sensor_id":sensor_id})
    fired {
      raise wrangler event "child_deletion"
        attributes {"name": sensor_id};
      clear ent:sensors{sensor_id}
    }
      
  }

  rule pico_ruleset_added {
    select when wrangler ruleset_added where rid == "sensor_profile"
    pre {
      sensor_id = event:attr("sensor_id")
      the_section = ent:sensors{sensor_id}
    }
    event:send(
            { "eci": the_section{"eci"}, "eid": "update-profile",
              "domain": "sensor", "type": "profile_update",
              "attrs": { "name": "Bobby Child", "threshold": 60, "number": 2082018898 } } )
  }

  rule collection_empty {
      select when collection empty
      send_directive("Empty")
      always {
        ent:sensors := {}
      }
    }

   rule subscribe_to_outside_sensor {
        select when sensor subscribe_outside_sensor
        pre{
            ip_addr = event:attr("ip")
            name = event:attr("name")
            eci = event:attr("eci")
        }
        always{
            raise wrangler event "subscription" attributes
                {   "name" : name,
                    "Rx_role": "manager",
                    "Tx_role": "sensor",
                    "channel_type": "subscription",
                    "wellKnown_Tx" : eci,
                    "Tx_host": <<http://#{ip_addr}:8080>>
                }
        }
    }
    
    rule get_outside_temps {
      select when sensor get_outside_temps
      foreach Subscriptions:established("Tx_role","sensor") setting (subscription)
      pre {
        thing_subs = subscription.klog("subs")
      }
      if subscription{"Tx_host"} != null
      then
        event:send(
          { "eci": subscription{"Tx"}, "eid": "subscription",
            "domain": "sensor", "type": "get_temps", "Tx_host": subscription{"Tx_host"} })
    }
    
    rule get_inside_temps {
      select when sensor get_inside_temps
      foreach Subscriptions:established("Tx_role","sensor") setting (subscription)
      pre {
        thing_subs = subscription.klog("subs")
      }
      // send_directive("hello")
      // if subscription{"Tx_host"} == null
      // then
        event:send(
          { "eci": subscription{"Tx"}, "eid": "subscription",
            "domain": "sensor", "type": "get_temps" })
    }
}