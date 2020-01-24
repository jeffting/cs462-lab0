ruleset io.picolabs.twilio_v2 {
    meta {
      configure using account_sid = ""
                      auth_token = ""
      provides
          send_sms,
          messages
    }
   
    global {
      send_sms = defaction(to, from, message) {
         base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
         http:post(base_url + "Messages.json", form = {
                  "From":+16235525839,
                  "To":2082018898,
                  "Body":"Hello Human"
              })
      }
      
      messages = defaction(to, from, pages) {
        base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
        http:get(base_url + "Messages", from = {
          "From":+16235525839,
          "To": 2082018898,
        })
      }
    }
  }