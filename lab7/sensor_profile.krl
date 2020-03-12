ruleset sensor_profile {
    meta {
        shares get_profile, get_threshold
        provides get_profile, get_threshold
    }

    global {
        get_profile = function() {
            profile = {"name": ent:name, "location": ent:location, "threshold": ent:threshold, "number": ent:number}
            profile
        }
        get_threshold = function() {
            ent:threshold.defaultsTo(75)
        }
    }
    rule update_profile {
        select when sensor profile_updated
        pre {
            location = event:attr("location") => event:attr("location") | ent:location
            name = event:attr("name") => event:attr("name") | ent:name
            threshold = event:attr("threshold") => event:attr("threshold") | ent:threshold
            number = event:attr("number") => event:attr("number") | ent:number
            thresholdDidChange = event:attr("threshold") => true | false
        }
        send_directive("data", {"name": ent:name, "location": ent:location, "threshold": ent:threshold, "number": ent:number})
        always {
            ent:location := location
            ent:name := name
            ent:threshold := threshold
            ent:number := number
        }
    }

    rule auto_accept {
        select when wrangler inbound_pending_subscription_added
        fired {
          raise wrangler event "pending_subscription_approval"
            attributes event:attrs
        }
      }

}