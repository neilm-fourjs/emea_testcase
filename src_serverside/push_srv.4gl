
IMPORT com
IMPORT util

IMPORT FGL push_db

&include "push.inc"

DEFINE m_api_key STRING
DEFINE m_reg_ids DYNAMIC ARRAY OF STRING
DEFINE m_recs DYNAMIC ARRAY OF t_reg_rec
MAIN
	DEFINE l_titl, l_mess, l_icon, l_res STRING

	DEFINE x SMALLINT

	CALL STARTLOG( base.Application.getProgramName()||".err" )

	CALL push_db.open_create_db()

	OPEN FORM f FROM "push_server"
	DISPLAY FORM f

	LET m_api_key = fgl_getEnv("PUSH_APIKEY")
	IF m_api_key.getLength() < 10 THEN
		CALL fgl_winMessage("Error","PUSH_APIKEY not set!","exclamation")
		EXIT PROGRAM
	END IF

	CALL get_data()
	LET l_titl = "my message title"
	LET l_mess = "my message text"
	LET l_icon = "information"

	DIALOG ATTRIBUTES(UNBUFFERED)
		INPUT BY NAME l_titl, l_mess, l_icon, l_res ATTRIBUTES(WITHOUT DEFAULTS)
		END INPUT
		DISPLAY ARRAY m_recs TO f_rec.* 
			ON ACTION toggle
				LET m_recs[ arr_curr() ].send = NOT m_recs[ arr_curr() ].send
		END DISPLAY
		ON ACTION refresh
			CALL get_data()
		ON ACTION send
			CALL m_reg_ids.clear()
		-- setup array of tokens to send message to
			FOR x = 1 TO m_recs.getLength()
				IF m_recs[x].send THEN
					LET m_reg_ids[ m_reg_ids.getLength() + 1 ] = m_recs[x].registration_token
				END IF
			END FOR
			IF m_reg_ids.getLength() > 0 THEN
				LET l_res = send_message(l_titl, l_mess, l_icon)
			ELSE
				LET l_res = "No targets selected"
			END IF
		ON ACTION cancel EXIT DIALOG
		ON ACTION close EXIT DIALOG
	END DIALOG

END MAIN
--------------------------------------------------------------------------------
FUNCTION get_data()
	CALL m_recs.clear()
	DECLARE c1 CURSOR FOR SELECT * FROM tokens ORDER BY id
	FOREACH c1 INTO m_recs[ m_recs.getLength() + 1 ].*
		LET m_recs[ m_recs.getLength()  ].send = FALSE		
	END FOREACH
	CALL m_recs.deleteElement( m_recs.getLength() )
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION send_message(l_titl, l_mess, l_icon)
	DEFINE l_titl, l_mess, l_icon, l_res STRING
	DEFINE l_notif_obj, l_popup_obj, l_data_obj util.JSONObject

	LET l_notif_obj = util.JSONObject.create()
	LET l_popup_obj = util.JSONObject.create()
	LET l_data_obj = util.JSONObject.create()
	CALL l_notif_obj.put("registration_ids", m_reg_ids)
	CALL l_popup_obj.put("title", "Emea TestCase Incoming Message!")
	CALL l_popup_obj.put("content", l_titl)
	CALL l_popup_obj.put("icon", "myicon")
	CALL l_data_obj.put("genero_notification", l_popup_obj)
	CALL l_data_obj.put("message", CURRENT HOUR TO SECOND||": "||l_mess)
	CALL l_data_obj.put("icon", l_icon)
	CALL l_data_obj.put("title", l_titl)
	CALL l_notif_obj.put("data", l_data_obj)

	DISPLAY "Sending:",l_notif_obj.toString()
	LET l_res = gcm_send_notif_http( m_api_key, l_notif_obj)
	DISPLAY "Result:", l_res
	DISPLAY "Finished."
	RETURN l_res
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION gcm_send_notif_http(l_api_key, l_notif_obj)
	DEFINE l_api_key STRING,
				 l_notif_obj util.JSONObject
	DEFINE l_req com.HTTPRequest,
				 l_resp com.HTTPResponse,
				 l_req_msg,  l_res STRING

	TRY
		LET l_req = com.HTTPRequest.Create("https://gcm-http.googleapis.com/gcm/send")
		CALL l_req.setHeader("Content-Type", "application/json")
		CALL l_req.setHeader("Authorization", SFMT("key=%1", l_api_key))

		CALL l_req.setMethod("POST")
		LET l_req_msg = l_notif_obj.toString()
		IF l_req_msg.getLength() >= 4096 THEN
			 LET l_res = ":ERROR : GCM message cannot exceed 4 kilobytes"
			 RETURN l_res
		END IF
		CALL l_req.doTextRequest(l_req_msg)
		LET l_resp = l_req.getResponse()
		IF l_resp.getStatusCode() != 200 THEN
			LET l_res = SFMT(":HTTP Error (%1) %2",
									 l_resp.getStatusCode(),
									 l_resp.getStatusDescription())
		ELSE
			LET l_res = ":Push notification sent!"
		END IF
	CATCH
		LET l_res = SFMT(":ERROR : %1 (%2)", STATUS, SQLCA.SQLERRM)
	END TRY
	RETURN CURRENT||l_res

END FUNCTION