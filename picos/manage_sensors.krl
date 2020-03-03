ruleset manage_sensors {
    meta {
        shares __testing
    }
    global {
        __testing = { "queries": [ { "name": "__testing" } ],
                      "events": [ { "domain": "post", "type": "test",
                                  "attrs": [ "temp", "baro" ] } ] 
                                }
    }

    rule new_sensor {
        select when sensor:new_sensor
        pre {
            session_name = event:attr("session_name")
            exists = ent:sessions >< session_name
            eci = meta:eci
        }
        if exists then
            send_directive("new sensor", { "session_name": session_name, "eci": eci})
        notfired {
            ent:sensors := ent:sensors.union([section_id])
            raise wrangler event "child_creation"
                attributes { "name": nameFromID(session_name), "color": "#ffff00" }
        }
    }
}