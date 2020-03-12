ruleset manage_sensors {
  meta {
      shares __testing, sensors
      use module io.picolabs.subscription alias Subscriptions
  }
  global {
      __testing = { "events":  [ { "domain": "sensor", "type": "new_sensor", "attrs": [ "sensor_id" ] }, {"domain": "collection", "type": "empty", "attrs": []} ] }

    sensors = function() {
      Subscriptions:established("Tx_role","sensor")
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
          raise sensor event "notify_outside" attributes {
            "name" : sensor_id,
            "eci" : the_section{"eci"}
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

    rule new_outside_sensor {
      select when sensor subscribe_outside_sensor 
      pre {
        eci = event:attr("eci")
        name = event:attr("name")
        ip_addr = event:attr("ip")
      }
      event:send(
        { "eci": eci, "eid": "subscription",
          "domain": "wrangler", "type": "subscription",
          "attrs": { "name": name,
                     "Rx_role": "manager",
                     "Tx_role": "sensor",
                     "channel_type": "subscription",
                     "wellKnown_Tx": eci } }, host="https://"+ip_addr+":8080" )
    }
}