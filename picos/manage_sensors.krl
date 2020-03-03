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
        select when sensor new_sensor
        pre {
            session_id = event:attr("session_id")
        }
        send_directive("new sensor", { "session_id": session_id, "eci": eci})
        fired {
            raise wrangler event "child_creation"
                attributes { "session_id": nameFromID(session_id), "color": "#ffff00" }
        }
    }

    rule store_new_section {
        select when wrangler child_initialized
        pre {
            the_section = {"id": event:attr("id"), "eci": event:attr("eci")}
            session_id = event:attr("session_id")
        }
        if session_id.klog("found section_id")
        then
            noop()
        fired {
            ent:sessions := ent:sessions.defaultsTo({});
            ent:sessions{[session_id]} := the_section
        }
    }

    rule collection_empty {
        select when collection empty
        always {
          ent:sessions := {}
        }
      }
}