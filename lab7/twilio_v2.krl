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
                "To":to,
                "Body":message
            })
    }
    
    messages = function(to, from, pageSize) {
      base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
      query_map = {}
      query_map = to.isnull() == false => query_map.put("To", to) | query_map
      query_map = from.isnull() == false => query_map.put("From", from) | query_map
      query_map = pageSize.isnull() == false => query_map.put("PageSize", pageSize) | query_map
      http:get(base_url + "Messages.json", qs = query_map){"content"}.decode()
    }
  }
}