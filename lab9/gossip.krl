ruleset gossip {
    meta {
        shares __testing, sensors, get_temps_func, get_report
        use module io.picolabs.subscription alias Subscriptions
    }
    
    global {

    }

    rule subscribe_to_pico {
        select when gossip subscribe
        pre {
            id = event:attr("id")
            eci = event:attr("eci")

        }
        always {
            raise wrangler event "subscription" attributes
            { "name" : id,
              "Rx_role": "sensor_manager",
              "Tx_role": "sensor",
              "channel_type": "subscription",
              "wellKnown_Tx" : eci
            }
        }
    }
}