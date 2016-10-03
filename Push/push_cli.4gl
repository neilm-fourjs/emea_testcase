
IMPORT com  -- For RESTful post
IMPORT util -- JSON API

FUNCTION push_reg(l_sender_id, l_server, l_badge_number, l_app_user)
	DEFINE l_sender_id, l_server, l_res, l_app_user STRING,
				 l_registration_token STRING
	DEFINE l_req com.HTTPRequest,
				 l_obj util.JSONObject,
				 l_resp com.HTTPResponse
	DEFINE l_badge_number INTEGER

-- First get the registration token
	CALL ui.Interface.frontCall(
			"mobile", "registerForRemoteNotifications", 
			[ l_sender_id ], [ l_registration_token ] )

	-- Then send registration token to push notification provider
	TRY
		LET l_req = com.HTTPRequest.create(l_server||"/token_maintainer/register")
		CALL l_req.setHeader("Content-Type", "application/json")
		CALL l_req.setMethod("POST")
		CALL l_req.setTimeOut(5)
		LET l_obj = util.JSONObject.create()
		CALL l_obj.put("registration_token", l_registration_token)
		CALL l_obj.put("badge_number", l_badge_number)
		CALL l_obj.put("app_user", l_app_user)
		CALL l_req.doTextRequest(l_obj.toString())
		LET l_resp = l_req.getResponse()
		IF l_resp.getStatusCode() != 200 THEN
			LET l_res = SFMT("HTTP Error (%1) %2",
								l_resp.getStatusCode(),
								l_resp.getStatusDescription())
		ELSE
			LET l_res = "Registration token sent."
		END IF
	CATCH
		LET l_res = SFMT("Could not post registration token to server: %1", STATUS)
	END TRY
	RETURN l_res
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION handle_notification(l_sender_id)
	DEFINE l_sender_id STRING,
		notif_list STRING,
		notif_array util.JSONArray,
		notif_item util.JSONObject,
		notif_data util.JSONObject,
		gcm_data, l_mess, l_icon, l_title STRING,
		i INTEGER

	CALL ui.Interface.frontCall(
		"mobile", "getRemoteNotifications",
		[ l_sender_id ], [ notif_list ] )
	TRY
		LET notif_array = util.JSONArray.parse(notif_list)
		IF notif_array.getLength() > 0 THEN
			CALL setup_badge_number(notif_array.getLength())
		END IF
		FOR i=1 TO notif_array.getLength()
			LET l_mess = NULL
			LET l_icon = "information"
			LET notif_item = notif_array.get(i)
			-- Try APNs msg format
			LET notif_data = notif_item.get("custom_data")
			IF notif_data IS NULL THEN
				-- Try GCM msg format
				LET gcm_data = notif_item.get("data")
				IF gcm_data IS NOT NULL THEN
					LET notif_data = util.JSONObject.parse(gcm_data)
				END IF
			END IF
			IF notif_data IS NOT NULL THEN
				LET l_mess = notif_data.get("message")
				LET l_title = notif_data.get("title")
				LET l_icon = notif_data.get("icon")
			END IF
			CALL fgl_winMessage(NVL(l_title,"Error"), NVL(l_mess,"NULL"),NVL(l_icon,"information"))
		END FOR
	CATCH
		ERROR "Could not extract notification info"
	END TRY
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION setup_badge_number(consumed)
	DEFINE consumed INTEGER
	DEFINE badge_number INTEGER
	TRY -- If the front call fails, we are not on iOS...
		CALL ui.Interface.frontCall("ios", "getBadgeNumber", [], [badge_number])
	CATCH
		RETURN
	END TRY
	IF badge_number>0 THEN
		LET badge_number = badge_number - consumed
	END IF
	CALL ui.Interface.frontCall("ios", "setBadgeNumber", [badge_number], [])
	{IF tm_command( "badge_number",
						 rec.sender_id, rec.registration_token,
						 rec.user_name, badge_number) < 0 THEN
		ERROR "Could not send new badge number to token maintainer."
		RETURN
	END IF}
END FUNCTION