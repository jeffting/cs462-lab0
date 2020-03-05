ruleset manage_sensors {
    meta {
        shares __testing
    }
    global {
        __testing = { "events":  [ { "domain": "sensor", "type": "new_sensor", "attrs": [ "sensor_id" ] }, {"domain": "collection", "type": "empty", "attrs": []} ] }
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
            attributes { "name": sensor_id, "color": "#ffff00" }
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
            noop()
        fired {
            ent:sensors := ent:sensors.defaultsTo({});
            ent:sensors{[sensor_id]} := the_section
        }
    }

    rule collection_empty {
        select when collection empty
        send_directive("Empty")
        always {
          ent:sensors := {}
        }
      }
}