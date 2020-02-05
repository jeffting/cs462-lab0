ruleset wovyn_base {
    meta {
      shares __testing
    }
    global {
      __testing = { "queries": [ { "name": "__testing" } ],
                    "events": [ { "domain": "post", "type": "test",
                                "attrs": [ "temp", "baro" ] } ] }
    }
   
    rule wovyn_base {
      select when wovyn heartbeat
      pre {
        never_used = event:attrs().klog("attrs")
      }
      send_directive("wovyn", {"hola": "Hello"})
    }
  }