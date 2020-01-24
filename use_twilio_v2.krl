ruleset io.picolabs.use_twilio_v2 {
    meta {
      use module io.picolabs.lesson_keys
      use module io.picolabs.twilio_v2 alias twilio
          with account_sid = keys:twilio{"account_sid"}
               auth_token =  keys:twilio{"auth_token"}
    }
   
    rule test_send_sms {
      select when test new_message
      twilio:send_sms(event:attr("to"),
                      event:attr("from"),
                      event:attr("message")
                     )
    }

    rule test_messages {
      select when test messages
      pre {
        base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
        content = http:get(base_url + "Messages", from = {
          "From":+16235525839,
          "To": 2082018898,
        })
      }
      send_directive("messages", {"data":content})
    }
  }