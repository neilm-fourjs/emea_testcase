
-- $Id: gm_remind_rest.4gl 99 2015-03-13 17:53:50Z neilm $

IMPORT util
IMPORT os
IMPORT com

DEFINE m_args DYNAMIC ARRAY OF RECORD
		cmd STRING,
		val STRING
	END RECORD
DEFINE m_version STRING
DEFINE m_rw_timeout SMALLINT
DEFINE m_content STRING
MAIN
  DEFINE l_req com.HttpServiceRequest
	DEFINE l_tmp STRING

	LET m_version = "1.02"
	LET m_rw_timeout = 20
	LET m_content = "text/plain"
-- Start an Error log
	CALL STARTLOG(base.application.getProgramName()||".err")

-- Log that we are running.
	CALL logIt("Listening ...")

-- Start WS engine.
	CALL com.WebServiceEngine.Start()
	CALL com.WebServiceEngine.SetOption( "readwritetimeout", m_rw_timeout )
-- Loop until we get an interrupt.
	LET int_flag = FALSE
	WHILE NOT int_flag
		LET l_req = com.WebServiceEngine.getHTTPServiceRequest(60)
		IF l_req IS NULL THEN -- shouldn't happen.
			CALL logIt("NO REQUEST")
			EXIT PROGRAM 0
		END IF
		CALL getParam(l_req.getURL()) -- get the args from the url
		IF m_args[1].cmd = "STOP" THEN
			LET int_flag = TRUE
			LET l_tmp = "Received Stop"
		ELSE
			LET l_tmp = process() -- Do actual processing.
		END IF
		CALL logIt("Processed:"||NVL(l_tmp,"NULL"))
		LET STATUS = 0
		CALL l_req.setResponseHeader("content-type",m_content)
		TRY
			CALL l_req.sendTextResponse(200, NULL, l_tmp) -- Send reply back
		CATCH
			CALL logIt("sendTextResponse Failed1:"||STATUS||" "||ERR_GET(STATUS))
		END TRY
		IF STATUS != 0 THEN
			CALL logIt("sendTextResponse Failed2:"||STATUS||" "||ERR_GET(STATUS))
		END IF
		SLEEP 1
		CALL logIt("Finished.")
	END WHILE
	EXIT PROGRAM 0

END MAIN
--------------------------------------------------------------------------------
#+ Break the URL down into a list of arguments.
#+ populates the m_args array
#+
#+ @param l_url The url for request.
#+ @returns none
FUNCTION getParam(l_url)
	DEFINE l_url, l_args STRING
	DEFINE l_st base.StringTokenizer
	DEFINE x SMALLINT

	CALL m_args.clear()

	CALL logIt("params:"||NVL(l_url,"NULL"))
	LET l_st = base.StringTokenizer.create(l_url,"?")
	LET l_args = l_st.nextToken() -- http:// etc
	LET l_args = l_st.nextToken() -- Arg=Whatever&Arg= etc

	LET l_st = base.StringTokenizer.create(l_args,"&")
	WHILE l_st.hasMoreTokens()
		LET m_args[ m_args.getLength() + 1 ].cmd = l_st.nextToken() -- Arg=Whatever
		LET x = m_args[ m_args.getLength() ].cmd.getIndexOf("=",1)
		IF x > 0 THEN
			LET m_args[ m_args.getLength() ].val = m_args[ m_args.getLength() ].cmd.subString(x+1,m_args[ m_args.getLength() ].cmd.getLength() )
			LET m_args[ m_args.getLength() ].cmd = m_args[ m_args.getLength() ].cmd.subString(1,x-1)
		END IF
		CALL logIt(SFMT("Arg:%1 %2=%3",m_args.getLength(),m_args[ m_args.getLength() ].cmd,m_args[ m_args.getLength() ].val))
	END WHILE

END FUNCTION
--------------------------------------------------------------------------------
#+ Process the arguments
#+
#+ @returns The String reply to send back.
FUNCTION process()
	DEFINE l_res STRING
	DEFINE l_int INTEGER
	DEFINE x SMALLINT

	LET l_res = SFMT("This is a test service\nVersion is %1\nThe read/write timeout is %2\n",m_version,m_rw_timeout)
	FOR x = 1 TO m_args.getLength()
		LET l_res = l_res.append( SFMT("Arg %1: %2=%3\n",x,m_args[x].cmd,m_args[x].val) )
		IF m_args[x].cmd = "sleep" THEN
			LET l_int = m_args[x].val
			LET l_res = l_res.append( SFMT("Slept for %1 seconds.\n",l_int) )
			SLEEP l_int
		END IF
	END FOR

	RETURN l_res
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION logit( l_msg )
	DEFINE l_msg STRING
	DEFINE c base.channel
	LET c = base.Channel.create()
	CALL c.openFile(base.application.getProgramName()||".log","a")
	CALL c.writeLine( CURRENT||":"||NVL(l_msg,"NULL") )
	DISPLAY "Log:"||CURRENT||":"||NVL(l_msg,"NULL")
	CALL c.close()
END FUNCTION
