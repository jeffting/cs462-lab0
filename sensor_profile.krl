ruleset sensor_profile {
    

    rule update_profile {
        select when sensor profile_updated
        pre {
            location = event:attr("location") => event:attr("location") | ent:location
            name = event:attr("name") => event:attr("name") | ent:name
            threshold = event:attr("threshold") => event:attr("threshold") | ent:threshold
        }
        send_directive("data", {"name": ent:name, "location": ent:location, "threshold": ent:threshold})
        always {
            ent:location := location
            ent:name := name
            ent:threshold := threshold
        }
    }
}