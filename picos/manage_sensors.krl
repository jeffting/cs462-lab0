ruleset manage_sensors {
    meta {
        shares __testing, sensors
    }
    global {
        __testing = { "events":  [ { "domain": "sensor", "type": "new_sensor", "attrs": [ "sensor_id" ] }, {"domain": "collection", "type": "empty", "attrs": []} ] }
    
      sensors = function() {
        ent:sensors
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
            attributes { "name": sensor_id, "color": "#ffff00", "rids": ["temperature_store", "wovyn_base", "sensor_profile"] }
        }
    }

    rule store_new_section {
        select when wrangler child_initialized
        pre {
            the_section = {"id": event:attr("id"), "eci": event:attr("eci")}
            sensor_id = event:attr("name")
        }
        if sensor_id.klog("found section_id")
        then
            event:send(
              { "eci": the_section{"eci"}, "eid": "update-profile",
                "domain": "sensor", "type": "profile_updated",
                "attrs": { "name": "Bobby Child", "threshold": 60, "number": 2082018898 } } )
        fired {
            ent:sensors := ent:sensors.defaultsTo({});
            ent:sensors{[sensor_id]} := the_section
            
        }
    }
    
    rule update_profile {
      select when sensor update_profile
      pre {
        eci = event:attr("eci").klog("EEEEEEEEE")
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
        sensor_id = event:attr("sensor_id").klog("AAAAA")
        the_section = ent:sensors{sensor_id}.klog("BBBBB: ")
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
}