IMPORT util
IMPORT com

&include "push.inc"

MAIN
	CALL open_create_db()
	CALL handle_registrations()
END MAIN
--------------------------------------------------------------------------------
FUNCTION open_create_db()
	DEFINE l_dbsrc VARCHAR(100)
	DEFINE x INTEGER

	LET l_dbsrc = "tokendb" --+driver='dbmsqt'"
	TRY
		CONNECT TO l_dbsrc
	CATCH
		CALL fgl_winMessage("Fatal",SFMT("Failed to connect to %1\n%2",l_dbsrc,SQLERRMESSAGE),"exclamation")
		EXIT PROGRAM
	END TRY

	WHENEVER ERROR CONTINUE
	SELECT COUNT(*) INTO x FROM tokens
	WHENEVER ERROR STOP

	IF SQLCA.SQLCODE < 0 THEN
		CREATE TABLE tokens (
			id INTEGER NOT NULL PRIMARY KEY,
			sender_id VARCHAR(150),
			registration_token VARCHAR(250) NOT NULL UNIQUE,
			badge_number INTEGER NOT NULL,
			app_user VARCHAR(50) NOT NULL, -- UNIQUE
			app_ver DECIMAL(5,2),
			cli_ver VARCHAR(20),
			reg_date DATETIME YEAR TO SECOND NOT NULL
		)
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION handle_registrations()
	DEFINE req com.HTTPServiceRequest,
				url, method, version, content_type STRING,
				reg_data, reg_result STRING

	IF LENGTH(fgl_getenv("FGLAPPSERVER")) = 0 THEN
	-- Normally, FGLAPPSERVER is set by the GAS
		DISPLAY SFMT("Setting FGLAPPSERVER to %1", C_REG_PORT)
		CALL fgl_setenv("FGLAPPSERVER", C_REG_PORT)
	END IF

	CALL com.WebServiceEngine.Start()
	WHILE TRUE
		TRY
			LET req = com.WebServiceEngine.getHTTPServiceRequest(20)
		CATCH
			IF STATUS==-15565 THEN
				DISPLAY "TCP socket probably closed by GAS, stopping process..."
				EXIT PROGRAM 0
			ELSE
				DISPLAY "Unexpected getHTTPServiceRequest() exception: ", STATUS
				DISPLAY "Reason: ", SQLCA.SQLERRM
				EXIT PROGRAM 1
			END IF
		END TRY
		IF req IS NULL THEN -- timeout
			DISPLAY SFMT("%1:HTTP request timeout...", CURRENT YEAR TO FRACTION)
			CALL check_apns_feedback()
			CALL show_tokens()
			CONTINUE WHILE
		END IF
		LET url = req.getURL()
		LET method = req.getMethod()
		IF method IS NULL OR method != "POST" THEN
			IF method == "GET" THEN
				CALL req.sendTextResponse(200,NULL, CURRENT||":Hello from token maintainer...")
			ELSE
				DISPLAY SFMT("Unexpected HTTP request: %1", method)
				CALL req.sendTextResponse(400,NULL,"Only POST requests supported")
			END IF
			CONTINUE WHILE
		END IF
		LET version = req.getRequestVersion()
		IF version IS NULL OR version != "1.1" THEN
				DISPLAY SFMT("Unexpected HTTP request version: %1", version)
				CONTINUE WHILE
		END IF
		LET content_type = req.getRequestHeader("Content-Type")
		IF content_type IS NULL OR content_type NOT MATCHES "application/json*" THEN -- ;Charset=UTF-8
			DISPLAY SFMT("Unexpected HTTP request header Content-Type: %1", content_type)
			CALL req.sendTextResponse(400,NULL,"Bad request")
			CONTINUE WHILE
		END IF
		TRY
			CALL req.readTextRequest() RETURNING reg_data
		CATCH
			DISPLAY SFMT("Unexpected HTTP request read exception: %1", STATUS)
		END TRY
		LET reg_result = process_command(url, reg_data)
		DISPLAY "Result:",reg_result
		CALL req.setResponseCharset("UTF-8")
		CALL req.setResponseHeader("Content-Type","application/json")
		CALL req.sendTextResponse(200,NULL,reg_result)
	END WHILE
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION process_command(url, data)
	DEFINE url, data STRING
	DEFINE data_rec t_reg_rec
	DEFINE l_rec t_reg_rec
	DEFINE p_id INTEGER,
			p_ts DATETIME YEAR TO FRACTION(3),
			result_rec RECORD
				status INTEGER,
				message STRING
			END RECORD

	LET result_rec.status = 0
	TRY
		CASE
			WHEN url MATCHES "*token_maintainer/register"
				CALL util.JSON.parse( data, data_rec )
				SELECT * INTO l_rec.* FROM tokens
								WHERE registration_token = data_rec.registration_token
				IF l_rec.id > 0 THEN
					LET result_rec.status = 1
					LET result_rec.message = "Token already registered."
					IF data_rec.app_ver != l_rec.app_ver THEN
						LET result_rec.message = result_rec.message.append("\nApp version updated.")
						UPDATE tokens SET app_ver = data_rec.app_ver WHERE registration_token = data_rec.registration_token
					END IF
					IF data_rec.cli_ver != l_rec.cli_ver THEN
						LET result_rec.message = result_rec.message.append("\nCli version updated.")
						UPDATE tokens SET cli_ver = data_rec.cli_ver WHERE registration_token = data_rec.registration_token
					END IF
					RETURN util.JSON.stringify(result_rec)
				END IF
				SELECT MAX(id) + 1 INTO p_id FROM tokens
				IF p_id IS NULL THEN LET p_id=1 END IF
				LET p_ts = util.Datetime.toUTC(CURRENT YEAR TO FRACTION(3))
				WHENEVER ERROR CONTINUE
				INSERT INTO tokens
						VALUES( p_id, data_rec.sender_id, data_rec.registration_token, data_rec.badge_number , data_rec.app_user,data_rec.app_ver, data_rec.cli_ver, p_ts )
				WHENEVER ERROR STOP
				IF SQLCA.SQLCODE = 0 THEN
					LET result_rec.message = SFMT("Token is now registered:\n [%1]", data_rec.registration_token)
				ELSE
					LET result_rec.status = -2
					LET result_rec.message = SFMT("Could not insert token in database:\n [%1]\%2", data_rec.registration_token, SQLERRMESSAGE)
				END IF

			WHEN url MATCHES "*token_maintainer/unregister"
				CALL util.JSON.parse( data, data_rec )
				DELETE FROM tokens
							WHERE registration_token = data_rec.registration_token
				IF SQLCA.SQLERRD[3] = 1 THEN
					LET result_rec.message = SFMT("Token unregistered:\n [%1]", data_rec.registration_token)
				ELSE
					LET result_rec.status = -3
					LET result_rec.message = SFMT("Could not find token in database:\n [%1]", data_rec.registration_token)
				END IF

			WHEN url MATCHES "*token_maintainer/badge_number"
				CALL util.JSON.parse( data, data_rec )
				WHENEVER ERROR CONTINUE
				UPDATE tokens SET badge_number = data_rec.badge_number
					WHERE registration_token = data_rec.registration_token
				WHENEVER ERROR STOP
				IF SQLCA.SQLCODE==0 THEN
					LET result_rec.message = SFMT("Badge number update succeeded for Token:\n [%1]\n New value for badge number :[%2]\n", data_rec.registration_token, data_rec.badge_number)
					ELSE
						LET result_rec.status = -4
						LET result_rec.message = SFMT("Could not update badge number for token in database:\n [%1]", data_rec.registration_token)
					END IF
			OTHERWISE
				DISPLAY "Bad URL:",url

		END CASE
	CATCH
		LET result_rec.status = -1
		LET result_rec.message = SFMT("Failed to register token:\n [%1]", data_rec.registration_token)
	END TRY
	DISPLAY "Data:", data

	RETURN util.JSON.stringify(result_rec)
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION show_tokens()
	DEFINE l_rec t_reg_rec

	DECLARE c1 CURSOR FOR SELECT * FROM tokens ORDER BY id
	FOREACH c1 INTO l_rec.*
		IF l_rec.sender_id IS NULL THEN
			LET l_rec.sender_id = "(null)"
		END IF
		DISPLAY "	", l_rec.id, ": ",
						l_rec.app_user[1,10], " / ",
						l_rec.app_ver, " / ",
						l_rec.cli_ver, " / ",
						l_rec.sender_id[1,20],"... / ",
						"(",l_rec.badge_number USING "<<<<&", ") ",
						l_rec.registration_token[1,20],"..."
	END FOREACH
	IF l_rec.id == 0 THEN
		DISPLAY SFMT("%1:No tokens registered yet...", CURRENT YEAR TO FRACTION)
	END IF
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION check_apns_feedback()
	DEFINE req com.TCPRequest,
				 resp com.TCPResponse,
				 feedback DYNAMIC ARRAY OF RECORD
						timestamp INTEGER,
						deviceToken STRING
					END RECORD,
				 timestamp DATETIME YEAR TO FRACTION(3),
				 token VARCHAR(250),
				 i INTEGER,
				 data BYTE

	IF NUM_ARGS() = 0 OR ARG_VAL(1) != "APNS" THEN RETURN END IF
	DISPLAY "Checking APNS feedback service..."

	LOCATE data IN MEMORY

	TRY
		LET req = com.TCPRequest.create( "tcps://feedback.push.apple.com:2196" )
		CALL req.setKeepConnection(true)
		CALL req.setTimeout(2)
		CALL req.doRequest()
		LET resp = req.getResponse()
		CALL resp.getDataResponse(data)
		CALL com.APNS.DecodeFeedback(data,feedback)
		FOR i=1 TO feedback.getLength()
			LET timestamp = util.Datetime.fromSecondsSinceEpoch(feedback[i].timestamp)
			LET timestamp = util.Datetime.toUTC(timestamp)
			LET token = feedback[i].deviceToken
			DELETE FROM tokens
				WHERE registration_token = token
					AND reg_date < timestamp
		END FOR
	CATCH
		CASE STATUS
			WHEN -15553 DISPLAY "APNS feedback: Timeout: No feedback message"
			WHEN -15566 DISPLAY "APNS feedback: Operation failed :", SQLCA.SQLERRM
			WHEN -15564 DISPLAY "APNS feedback: Server has shutdown"
			OTHERWISE	 DISPLAY "APNS feedback: ERROR :",STATUS
		END CASE
	END TRY
END FUNCTION