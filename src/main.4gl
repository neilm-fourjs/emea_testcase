--SCHEMA mydatabase
IMPORT os
IMPORT util
IMPORT security
IMPORT com

IMPORT FGL push_cli
IMPORT FGL lib_db

&include "../src_serverside/push.inc"

CONSTANT c_appver = "3.23"
CONSTANT C_TESTDIR = "/sdcard/testdir"
--CONSTANT C_RESTTEST_URL = "https://gpaas1.generocloud.net/g5/ws/r/m/rt?sleep=2"
CONSTANT C_RESTTEST_URL = "https://www.4js-emea.com/dr/ws/r/resttest?sleep=2"

	DEFINE m_dir STRING -- restfull test 
	DEFINE m_cmd STRING -- restfull test 
	DEFINE m_cli STRING -- GMA / GMI
	DEFINE m_cli_ver STRING -- Client / version
	DEFINE m_cli_info STRING -- App + Client / version
	DEFINE m_url, m_msg, m_content STRING -- restfull test 
	DEFINE m_con_timeout, m_timeout,m_rw_timeout INTEGER -- restfull test 
	DEFINE m_done_cre, m_done_req, m_done_res BOOLEAN -- restfull test 
	DEFINE m_req com.HttpRequest -- restfull test 
	DEFINE m_res com.HttpResponse -- restfull test 
	DEFINE m_add_runno BOOLEAN -- restfull test 
	DEFINE m_geo_loc STRING
	DEFINE m_conn STRING
	DEFINE m_probs DYNAMIC ARRAY OF RECORD
		titl STRING,
		desc STRING,
		icon STRING
	END RECORD
MAIN
	DEFINE l_dummy STRING
	DEFINE l_first_time BOOLEAN

	WHENEVER ERROR CALL erro

	IF  ARG_VAL(1) = "getgps" THEN
		CALL getgps()
		EXIT PROGRAM
	END IF

	CALL init_app()
-- problems array setup:
	CALL add_prob(1,"Limitation Ex1.","Simple 'type' selector infront of field","fa-arrow-circle-right")
	CALL add_prob(2,"ButtonEdit bug.","buttonEdit image over text.","fa-bug")
	CALL add_prob(3,"Textedit working here","textEdit not expanding.","smiley")
	CALL add_prob(4,"Limitation Ex2.","Getting a sequence of digits in a nice way.","fa-arrow-circle-right")
	CALL add_prob(5,"Missing Image.","Multiple Actions / icons wrong.","ssmiley")
	CALL add_prob(6,"Action Issue","Hidden vs Active Action, shouldn't be clickable.","ssmiley")
	CALL add_prob(7,"Styles test","Styles test - GMI missing icon on button.","ssmiley")
	CALL add_prob(8,"List Issue","Moving from a list and back.","ssmiley")
	CALL add_prob(9,"os.path", "os.path tests, copy fails!","ssmiley")
	CALL add_prob(10,"GoogleMaps","Simple test for a WC","fa-map")
	CALL add_prob(11,"Choose an Image","Choosing an image with Google Photos App","smiley")
	CALL add_prob(12,"Take a Photo","Take a photo and store it in a specific folder","camera")
	CALL add_prob(13,"shellexec pdf","Attempt to open a PDF","fa-file-pdf-o")
	CALL add_prob(14,"RESTFUL call","Testing restful calls to a simple service","fa-arrow-circle-right")
	CALL add_prob(15,"GEO Location","Open a GEO location with default app","fa-map-marker")
	CALL add_prob(16,"Email","Sending an Email","mail")
	CALL add_prob(17,"FrontCalls","Various frontCalls","fa-arrow-circle-right")
	CALL add_prob(18,"Widgets/Dialog Touched","Various Widgets & Dialog Touched","fa-bug")
	CALL add_prob(19,"Single Checkbox","requires two taps","fa-bug")
	CALL add_prob(20,"FAB action","Floating Action Button","smiley")
	CALL add_prob(21,"Register for PUSH","Register for PUSH","fa-flag-o")
	CALL add_prob(22,"Run without waiting","Run without waiting - async","fa-flag-o")
	CALL add_prob(23,"Layouting options #1","Layouting options #1","fa-tv")
	CALL add_prob(24,"Layouting options #2","Layouting options #2","fa-tv")
	CALL add_prob(25,"Layouting - Split Layout","Layouting - Split Layout","fa-tv")
	CALL add_prob(26,"Local Database","Local Database","fa-database")
	CALL add_prob(27,"WC Signature","Signature Webcomponent","fa-tv")

	OPEN FORM f FROM "form"
	DISPLAY FORM f
	DISPLAY CURRENT TO l_curr
	DISPLAY BY NAME m_cli_info
	LET l_first_time = TRUE

	DIALOG
		INPUT BY NAME l_dummy
		END INPUT
		DISPLAY ARRAY m_probs TO menu.* --ATTRIBUTE(ACCEPT=FALSE,CANCEL=FALSE)
			BEFORE ROW
				--IF NOT l_first_time THEN
					CALL LOG("Doing test:"||m_probs[arr_curr()].desc)
					CALL do_test( arr_curr() )
					NEXT FIELD l_dummy
				--ELSE
				--	LET l_first_time = FALSE
				--END IF
		END DISPLAY
		ON ACTION close EXIT DIALOG
		ON ACTION about CALL about()
		ON ACTION exit EXIT DIALOG
		ON IDLE 15
			DISPLAY CURRENT TO l_curr
		ON ACTION notificationpushed
			CALL push_cli.handle_notification(C_SENDER_ID, c_appver, m_cli_ver)
	END DIALOG
	CALL log("Finished")
END MAIN
--------------------------------------------------------------------------------
FUNCTION init_app()
	DEFINE l_ret INTEGER
	LET m_dir = C_TESTDIR
	IF NOT os.path.exists( m_dir ) THEN
		IF NOT os.path.mkdir( m_dir ) THEN
			CALL fgl_winMessage("Error",SFMT("Failed to create %1\n%2-%3\nUsing %4",m_dir,STATUS,ERR_GET(STATUS),os.Path.pwd()),"exclamation")
			LET m_dir = os.Path.pwd()
		END IF
	END IF
	LET m_cli = UPSHIFT(ui.Interface.getFrontEndName())
	IF m_cli = "GMA" THEN
		TRY
			CALL ui.Interface.frontCall("android", "askForPermission", 
									["android.permission.WRITE_EXTERNAL_STORAGE"],[l_ret] )
		CATCH
			CALL fgl_winMessage("Error",SFMT("Failed 'askForPermission' %1",l_ret),"exclamation")
		END TRY
		CALL push_cli.handle_notification(C_SENDER_ID, c_appver, m_cli_ver)
	END IF
	TRY
		CALL STARTLOG( os.path.join( m_dir,base.Application.getProgramName()||".err" ) )
	CATCH
		CALL fgl_winMessage("Error",SFMT("Failed to start error log\n%1\n%2-%3\nUsing %4",m_dir,STATUS,ERR_GET(STATUS),os.Path.pwd()),"exclamation")
	END TRY
	LET m_cli_ver = m_cli," ",ui.Interface.getFrontEndVersion()
	LET m_cli_info = c_appver," Cli:",m_cli_ver
	CALL log("Started:"||NVL(m_cli_info ,"NULL Client") )
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION add_prob( l_x,l_titl, l_desc, l_icon )
	DEFINE l_x SMALLINT
	DEFINE l_titl, l_desc, l_icon STRING
	IF l_icon IS NULL THEN LET l_icon = "info" END IF
	LET m_probs[ l_x ].titl = l_x||". "||l_titl
	LET m_probs[ l_x ].desc = l_desc
	LET m_probs[ l_x ].icon = l_icon
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION about()
	DEFINE ar DYNAMIC ARRAY OF RECORD
		info STRING,
		val STRING
	END RECORD
	LET ar[ ar.getLength() + 1 ].info = "App ver:" LET ar[ ar.getLength() ].val = c_appver
	LET ar[ ar.getLength() + 1 ].info = "Client:" LET ar[ ar.getLength() ].val = m_cli_ver
	LET ar[ ar.getLength() + 1 ].info = "DVM Ver:" LET ar[ ar.getLength() ].val = fgl_getVersion()
	LET ar[ ar.getLength() + 1 ].info = "IMG Path:" LET ar[ ar.getLength() ].val = NVL(fgl_getEnv("FGLIMAGEPATH"),"NULL")
	LET ar[ ar.getLength() + 1 ].info = "DB Path:" LET ar[ ar.getLength() ].val = NVL(fgl_getEnv("DBPATH"),"NULL")
	LET ar[ ar.getLength() + 1 ].info = "Test Dir:" LET ar[ ar.getLength() ].val = m_dir
	LET ar[ ar.getLength() + 1 ].info = "Rest URL:" LET ar[ ar.getLength() ].val = C_RESTTEST_URL
	OPEN WINDOW about WITH FORM "about"
	DISPLAY ARRAY ar TO arr.* ATTRIBUTES(ACCEPT=FALSE,CANCEL=FALSE)
		ON ACTION gma_about CALL ui.interface.frontCall("Android","showAbout",[],[])
		ON ACTION back EXIT DISPLAY
		ON ACTION close EXIT DISPLAY
	END DISPLAY
	CLOSE WINDOW about
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION do_test( x )
	DEFINE x SMALLINT
	CASE x
		WHEN 1 CALL prob1()
		WHEN 2 CALL prob2()
		WHEN 3 CALL prob3()
		WHEN 4 CALL prob4()
		WHEN 5 CALL prob5()
		WHEN 6 CALL prob6()
		WHEN 7 CALL prob7()
		WHEN 8 CALL prob8()
		WHEN 9 CALL prob9()
		WHEN 10 CALL prob10()
		WHEN 11 CALL prob11()
		WHEN 12 CALL prob12()
		WHEN 13 CALL prob13()
		WHEN 14 CALL prob14()
		WHEN 15 CALL prob15()
		WHEN 16 CALL prob16()
		WHEN 17 CALL prob17()
		WHEN 18 CALL prob18()
		WHEN 19 CALL prob19()
		WHEN 20 CALL prob20()
		WHEN 21 CALL push_cli.push_register(c_appver, m_cli_ver)
		WHEN 22 CALL prob22() --      1234567890123456789012345678901234567890123456789
		WHEN 23 CALL prob23("prob23","This is a very long Title that may get truncated.")
		WHEN 24 CALL prob23("prob24","This is a Title")
		WHEN 25 CALL prob25()
		WHEN 26 CALL prob26()
		WHEN 27 CALL prob27()
	END CASE
END FUNCTION
--------------------------------------------------------------------------------
-- simple 'type' selector infront of field
FUNCTION prob1()
	DEFINE ptyp, pno STRING

	OPEN WINDOW p1 WITH FORM "prob1"

	DISPLAY "My Heading"
	LET ptyp = "Home"

	INPUT BY NAME ptyp, pno WITHOUT DEFAULTS

	CLOSE WINDOW p1
END FUNCTION
--------------------------------------------------------------------------------
-- buttonEdit image over text.
-- icon scale
FUNCTION prob2()
	DEFINE fld1 STRING

	OPEN WINDOW p2 WITH FORM "prob2"

	INPUT BY NAME fld1
		ON ACTION but1
			CALL fgl_winMessage("Info","You Clicked the buttonEdit","information")
		ON ACTION img1
			CALL fgl_winMessage("Info","You Clicked the button #1","information")
		ON ACTION img2
			CALL fgl_winMessage("Info","You Clicked the button #2","information")
		ON ACTION img3
			CALL fgl_winMessage("Info","You Clicked the button #3","information")
	END INPUT

	CLOSE WINDOW p2
END FUNCTION
--------------------------------------------------------------------------------
-- textedit not expanding.
FUNCTION prob3()
	DEFINE txt1,fld1 STRING
	DEFINE fld2 DATE
	DEFINE fld3 DATETIME YEAR TO SECOND
	DEFINE fld4 DECIMAL(10,2)

	OPEN WINDOW p3 WITH FORM "prob3"

	LET txt1 = "This is some text\nYou should see\nat least 4 lines\nof text displayed."
	DISPLAY txt1 TO txt2
	LET fld1 = "some data"
	LET fld2 = TODAY
	LET fld3 = CURRENT
	LET fld4 = 69.69
	DISPLAY BY NAME txt1, fld1,fld2, fld3, fld4
	MENU
		ON ACTION back EXIT MENU
		ON ACTION CLOSE EXIT MENU
	END MENU

	CLOSE WINDOW p3
END FUNCTION
--------------------------------------------------------------------------------
-- Getting a sequence of digits in a nice way.
FUNCTION prob4()
	DEFINE a,b,c,d,e,nums SMALLINT

	OPEN WINDOW p4 WITH FORM "prob4"

	INPUT BY NAME a,b,c,d,e,nums WITHOUT DEFAULTS

	CLOSE WINDOW p4
END FUNCTION
--------------------------------------------------------------------------------
-- Multiple Actions / icons wrong
-- Input numbers
FUNCTION prob5()
	DEFINE fld1 SMALLINT
	DEFINE fld2 DECIMAL(10,2)

	OPEN WINDOW p5 WITH FORM "prob5"

	LET fld1 = "Try the actions"
	LET fld2 = "if you can."

	INPUT BY NAME fld1, fld2 WITHOUT DEFAULTS
		BEFORE INPUT 
			CALL DIALOG.setActionHidden("act2", TRUE )
		ON ACTION act1
			MENU "MenuAction" ATTRIBUTE(STYLE="dialog",comment="You Clicked the action #1", IMAGE="myicon")
				ON ACTION CLOSE EXIT MENU
				ON ACTION okay EXIT MENU
			END MENU
		ON ACTION act2
			CALL fgl_winMessage("Info","You Clicked the action #2","information")
		ON ACTION act3
			CALL fgl_winMessage("Info","You Clicked the action #3","information")
		ON ACTION act4
			CALL fgl_winMessage("Info","You Clicked the action #4","information")
		ON ACTION act5
			CALL fgl_winMessage("Info","You Clicked the action #5","information")
	END INPUT

	CLOSE WINDOW p5
END FUNCTION
--------------------------------------------------------------------------------
-- Hidden vs Active Action
FUNCTION prob6()
	DEFINE l_fld0, l_fld1, l_fld2, l_fld3, l_fld4, l_fld5, l_res STRING
	DEFINE l_f ui.Form
	DEFINE w ui.Window
	DEFINE l_a1 BOOLEAN
	OPEN WINDOW p6 WITH FORM "prob6"
	LET w = ui.Window.getCurrent()
	CALL w.setImage(" ")
	CALL ui.Interface.setImage(" ")

	LET l_fld1 = "Enabled, Visible"
	LET l_fld2 = "Hidden"
	LET l_fld3 = "Enabled, Visible"
	LET l_fld4 = "Disabled, Visible"
	LET l_fld5 = "Enabled, Visible"
	INPUT BY NAME l_fld0, l_fld1, l_fld2, l_fld3, l_fld4, l_fld5, l_res ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED)
		BEFORE INPUT
			LET l_f = DIALOG.getForm()
			CALL DIALOG.setActionHidden("act2", TRUE )
			CALL DIALOG.setActionActive("act4",FALSE )
		ON ACTION act1
			LET l_res = "You Clicked the action #1"
		ON ACTION act2
			LET l_res = "You Clicked the action #2"
			LET l_a1 = NOT l_a1
			IF l_a1 THEN 
				CALL l_f.setElementImage("act2","ssmiley")
				CALL l_f.setElementImage("act4","smiley")
			ELSE
				CALL l_f.setElementImage("act2","smiley")
				CALL l_f.setElementImage("act4","ssmiley")
			END IF
		ON ACTION act3
			LET l_res = "You Clicked the action #3"
			CALL DIALOG.setActionHidden("act2", TRUE )
			CALL DIALOG.setActionActive("act4",FALSE )
			LET l_fld2 = "Hidden"
			LET l_fld4 = "Disabled, Visible"
		ON ACTION act4
			LET l_res ="You Clicked the action #4"
			LET l_a1 = NOT l_a1
			IF l_a1 THEN 
				CALL l_f.setElementImage("act2","ssmiley")
				CALL l_f.setElementImage("act4","smiley")
			ELSE
				CALL l_f.setElementImage("act2","smiley")
				CALL l_f.setElementImage("act4","ssmiley")
			END IF
		ON ACTION act5
			LET l_res = "You Clicked the action #5"
			CALL DIALOG.setActionHidden("act2", FALSE )
			CALL DIALOG.setActionActive("act4",TRUE )
			LET l_fld2 = "Enabled, Visible"
			LET l_fld4 = "Enabled, Visible"
	CALL add_prob(23,"Layouting options #1","Layouting options #1","info")	END INPUT

	CLOSE WINDOW p6
END FUNCTION
--------------------------------------------------------------------------------
-- Styles
FUNCTION prob7()
	DEFINE txt1,fld1 STRING
	DEFINE fld2 DATE
	DEFINE fld3 DATETIME YEAR TO SECOND
	DEFINE fld4 DECIMAL(10,2)

	OPEN WINDOW p7 WITH FORM "prob7"

	LET txt1 = "This is some text\nYou should see\nat least 4 lines\nof text displayed."
	DISPLAY txt1 TO txt1
	DISPLAY txt1 TO txt2
	LET fld1 = "some data"
	LET fld2 = TODAY
	LET fld3 = CURRENT
	LET fld4 = 69.69
	INPUT BY NAME fld1,fld2, fld3, fld4  ATTRIBUTE(ACCEPT=FALSE,CANCEL=FALSE,WITHOUT DEFAULTS)
		ON ACTION back EXIT INPUT
		ON ACTION CLOSE EXIT INPUT
		ON ACTION but1
			CALL fgl_winMessage("Info","You Clicked the buttonEdit","information")
		ON ACTION img1
			CALL fgl_winMessage("Info","You Clicked the button #1","information")
		ON ACTION img2
			CALL fgl_winMessage("Info","You Clicked the button #2","information")
		ON ACTION img3
			CALL fgl_winMessage("Info","You Clicked the button #3","information")
	END INPUT

	CLOSE WINDOW p7
END FUNCTION
--------------------------------------------------------------------------------
-- List
FUNCTION prob8()
	DEFINE arr DYNAMIC ARRAY OF RECORD
		titl STRING,
		desc STRING,
		icon STRING
	END RECORD
	DEFINE x SMALLINT

	FOR x = 1 TO 8
		LET arr[x].titl = x," Item"
		LET arr[x].desc = "This is test item ",x
		LET arr[x].icon = "icon"||x
	END FOR

	OPEN WINDOW p8 WITH FORM "prob8"

	DISPLAY ARRAY arr TO arr.* ATTRIBUTE(CANCEL=FALSE)
		ON ACTION ACCEPT
			IF arr_curr() != 8 THEN CALL do_test( arr_curr() ) END IF
		ON ACTION back EXIT DISPLAY
		ON ACTION CLOSE EXIT DISPLAY
	END DISPLAY

	CLOSE WINDOW p8
END FUNCTION
--------------------------------------------------------------------------------
-- os.path.
FUNCTION prob9()
	DEFINE l_msg, l_src, l_trg, l_dir STRING
	DEFINE l_paths DYNAMIC ARRAY OF RECORD
		path STRING,
		exist BOOLEAN
	END RECORD
	DEFINE x, l_stat SMALLINT
	DEFINE l_c base.Channel
	OPEN WINDOW p9 WITH FORM "prob9"

	LET l_msg = "os.path.separator is "||os.path.separator()||"\n"
	DISPLAY BY NAME l_msg
	LET l_msg = l_msg.append( "os.path.pwd is "||os.path.pwd()||"\n" )
	DISPLAY BY NAME l_msg

	LET l_src = os.path.join(m_dir, "emea_testcase.txt")
	LET l_dir = m_dir||"2"
	MENU
		ON ACTION back EXIT MENU
		ON ACTION CLOSE EXIT MENU

		ON ACTION mkdir
			IF os.path.exists( l_dir ) THEN
				LET l_msg = l_msg.append( SFMT( "os.path.mkdir %1 already exists!\n",l_dir) )
			ELSE
				IF os.path.mkdir( l_dir ) THEN
					LET l_msg = l_msg.append( SFMT("os.path.mkdir %1 worked\n",l_dir) )
				ELSE
					LET l_msg = l_msg.append( SFMT("os.path.mkdir  failed: %1\n",l_dir, STATUS) )
				END IF
			END IF
			DISPLAY BY NAME l_msg
		ON ACTION create
			TRY
				LET l_c = base.Channel.create()
				CALL l_c.openFile(l_src,"w")
				CALL l_c.writeLine( "Test" )
				CALL l_c.close()
				LET l_msg = l_msg.append( SFMT("file created:%1\n",l_src) )
			CATCH
				LET l_msg = l_msg.append( SFMT("Failed to create:%1\n",l_src) )
			END TRY
			DISPLAY BY NAME l_msg
		ON ACTION copy
			LET l_trg = l_src||".copy"
			LET l_stat = os.path.copy( l_src, l_trg )
			IF l_stat THEN
				LET l_msg = l_msg.append( "os.path.copy worked\n" )
			ELSE
				LET l_msg = l_msg.append( SFMT("os.path.copy failed: %1 %2\n", l_stat,STATUS) )
			END IF
			DISPLAY BY NAME l_msg
		ON ACTION remove
			IF os.Path.exists( l_src ) THEN LET l_trg = l_src END IF
			LET l_stat = os.path.delete( l_trg )
			IF l_stat THEN
				LET l_msg = l_msg.append( SFMT("os.path.delete of %1 worked\n",l_trg) )
			ELSE
				LET l_msg = l_msg.append( SFMT("os.path.delete of %1 failed: %2 %3\n",l_trg, l_stat,STATUS) )
			END IF
			DISPLAY BY NAME l_msg
		ON ACTION rename
			LET l_trg = l_src||".rename"
			LET l_stat = os.path.rename( l_src, l_trg )
			IF l_stat THEN
				LET l_msg = l_msg.append( "os.path.rename worked\n" )
			ELSE
				LET l_msg = l_msg.append( SFMT("os.path.rename failed: %1 %2\n", l_stat,STATUS) )
			END IF
			DISPLAY BY NAME l_msg

		ON ACTION exists
			LET l_paths[l_paths.getLength()+1].path = "/storage/emulated/0/download"  # Samsung Grand & S5
			LET l_paths[l_paths.getLength()+1].path = "/storage/sdcard0/download" # Samsung S3 Mini
			LET l_paths[l_paths.getLength()+1].path = "/mnt/sdcard/download"  # Fujitsu tablet
			LET l_paths[l_paths.getLength()+1].path = "/sdcard" # Nexus
			LET l_paths[l_paths.getLength()+1].path = C_TESTDIR # Nexus
			FOR x = 1 TO l_paths.getLength()
				LET l_paths[x].exist = os.Path.exists(l_paths[x].path)
				LET l_msg = l_msg.append(l_paths[x].path||" "||l_paths[x].exist||"\n")
				IF l_paths[x].exist THEN
					LET l_msg = l_msg.append( write_test( l_paths[x].path ) )
				END IF
			END FOR
			DISPLAY BY NAME l_msg
	END MENU
	CLOSE WINDOW p9
END FUNCTION
--------------------------------------------------------------------------------
-- Google maps Web Component
FUNCTION prob10()
	DEFINE lat, lat2, lng, lng2, wc_data, in_data STRING
	DEFINE l_tf BOOLEAN

	OPEN WINDOW p10 WITH FORM "prob10"

	{CALL ui.Interface.frontCall("standard","setwebcomponentpath", os.path.pwd(),l_tf)
	IF NOT l_tf THEN
		CALL fgl_winMessage("Error","Failed to set setwebcomponentpath!","exclamation")
		EXIT PROGRAM
	END IF}

-- Old
	LET lat = "50.8462723212"
	LET lng = "-0.2846145630"
-- New
	LET lat2 = "50.840805203"
	LET lng2 = "-0.3346055746"

	LET wc_data = "fred"

	CALL wc_setProp("lat",lat)
	CALL wc_setProp("lng",lng)

	INPUT BY NAME wc_data, lat, lng, in_data  ATTRIBUTE(CANCEL=FALSE,UNBUFFERED, WITHOUT DEFAULTS)
		ON ACTION go
			CALL wc_setProp("lat",lat2)
			CALL wc_setProp("lng",lng2)
		ON ACTION back EXIT INPUT
		ON ACTION mapclicked
			LET in_data = wc_data
			CALL deCode(in_data) RETURNING lat, lng
			DISPLAY "Map Clicked:", lat," ", lng
		ON ACTION CLOSE EXIT INPUT
	END INPUT

	CLOSE WINDOW p10

END FUNCTION
--------------------------------------------------------------------------------
-- Choose a photo
FUNCTION prob11()
	DEFINE l_file DYNAMIC ARRAY OF STRING
	DEFINE l_saved STRING
	DEFINE l_jsonarr util.JSONArray
	DEFINE l_c base.Channel
	DEFINE x SMALLINT
	LET l_saved = os.path.join( m_dir,"photos.json" )

	IF os.path.exists( l_saved ) THEN
		LET l_c = base.Channel.create()
		CALL l_c.openFile( l_saved, "r" )
		IF  l_c.read(l_saved ) THEN
			LET l_jsonarr = util.JSONArray.parse(l_saved)
			CALL l_jsonarr.toFGL(l_file)
		END IF
		CALL l_c.close()
	END IF

	OPEN WINDOW p11 WITH FORM "prob11"

	DISPLAY ARRAY l_file TO arr.* ATTRIBUTE(UNBUFFERED,CANCEL=FALSE)
		ON ACTION choose
			LET x = arr_curr()
			LET x = x + 1
			TRY
				CALL ui.interface.frontcall("mobile","choosePhoto",[],[l_file[ x ]])
			CATCH
				CALL fgl_winMessage("Error",SFMT("choosePhoto Failed\n%1",ERR_GET(STATUS)),"exclamation")
			END TRY
			DISPLAY l_file[ x ] TO img

		BEFORE ROW
			LET x = arr_curr()
			DISPLAY l_file[ x ] TO img

		ON ACTION close EXIT DISPLAY
		ON ACTION back EXIT DISPLAY
	END DISPLAY

	IF l_file.getLength() > 0 THEN
		LET l_jsonarr = util.JSONArray.fromFGL( l_file )
		LET l_c = base.Channel.create()
		TRY
			CALL l_c.openFile( l_saved, "w" )
			CALL l_c.write( l_jsonarr.toString() )
			CALL l_c.close()
		CATCH
			CALL fgl_winMessage("Error",SFMT("openFile failed %1\n%2",l_saved, err_get(STATUS)),"exclamation")
		END TRY
	END IF

	CLOSE WINDOW p11
END FUNCTION
--------------------------------------------------------------------------------
-- Take a photo and store it in a specific folder
FUNCTION prob12()
	DEFINE l_file, l_newfile STRING
	DEFINE l_msg STRING
	OPEN WINDOW p12 WITH FORM "prob12"

	MENU
		ON ACTION takepic
			TRY
				CALL ui.interface.frontcall("mobile","takePhoto",[],l_file)
			CATCH
				CALL fgl_winMessage("Error",SFMT("takePhoto Failed\n%1",ERR_GET(STATUS)),"exclamation")
			END TRY
			IF l_file IS NOT NULL THEN
				DISPLAY l_file TO img
			END IF
			DISPLAY l_file TO oldfile
		ON ACTION moveit
			IF l_file IS NOT NULL THEN
				IF NOT os.path.exists( m_dir ) THEN
					IF os.path.mkdir( m_dir ) THEN
						LET l_msg = l_msg.append( SFMT( "os.path.mkdir %1 worked\n",m_dir) )
					ELSE
						LET l_msg = l_msg.append( SFMT( "os.path.mkdir  failed: %1\n",m_dir, STATUS) )
					END IF
				ELSE
					LET l_msg = l_msg.append( SFMT( "folder %1 already exists\n",m_dir) )
				END IF
				LET l_newfile = security.RandomGenerator.CreateUUIDString()||".jpg"
				LET l_newfile = os.path.join(m_dir, l_newfile )
				IF os.path.copy( l_file, l_newfile ) THEN
					LET l_msg = l_msg.append( "os.path.copy worked\n" )
				ELSE
					LET l_msg = l_msg.append( SFMT( "os.path.copy failed: %1\n", STATUS) )
				END IF
				DISPLAY l_newfile TO newfile
				DISPLAY l_msg TO msg
				DISPLAY l_file TO img
			END IF
		ON ACTION CLOSE EXIT MENU
		ON ACTION EXIT EXIT MENU
	END MENU

	CLOSE WINDOW p12
END FUNCTION
--------------------------------------------------------------------------------
-- Attempt to open a PDF
FUNCTION prob13()
	DEFINE l_file STRING
	DEFINE l_res BOOLEAN

	LET l_file = os.path.join( m_dir, "Martin-Catalog.pdf" )
	IF NOT os.Path.exists( l_file ) THEN
		CALL fgl_winMessage("Error",SFMT("File does exist!\n%1",l_file),"exclamation")
		RETURN
	END IF

	MENU ATTRIBUTE(STYLE="dialog")
		ON ACTION shellexec
			TRY
				CALL ui.interface.frontcall("standard","shellexec",l_file,l_res)
			CATCH
				CALL fgl_winMessage("Error",SFMT("shellexec %1 failed\nStatus:%2 %3",l_file,STATUS,ERR_GET(STATUS)),"exclamation")
			END TRY
			IF NOT l_res THEN
				CALL fgl_winMessage("Error",SFMT("shellexec %1 returned false\nStatus:%2-%3",l_file,STATUS,ERR_GET(STATUS)),"exclamation")
			END IF

		ON ACTION launchurl
			TRY
				CALL ui.interface.frontcall("standard","launchurl","file://"||l_file,[])
			CATCH
				CALL fgl_winMessage("Error",SFMT("launchurl %1 failed\nStatus:%2 %3",l_file,STATUS,ERR_GET(STATUS)),"exclamation")
			END TRY

		ON ACTION CLOSE EXIT MENU
	END MENU
END FUNCTION
--------------------------------------------------------------------------------
-- RESTFUL WS Calls
FUNCTION prob14()
	DEFINE l_ret BOOLEAN
	DEFINE x SMALLINT
	OPEN WINDOW p14 WITH FORM "prob14"

	LET m_done_cre = FALSE
	LET m_done_req = FALSE
	LET m_done_res = FALSE
	LET m_url = C_RESTTEST_URL
	LET m_content = "text/plain"
	LET m_con_timeout = 10
	LET m_timeout = 15
	LET m_rw_timeout = 5
	LET m_cmd = ""
	LET m_msg = ""
	LET x = 0
	LET m_cmd = NULL
	LET m_add_runno = TRUE

	DIALOG ATTRIBUTE( UNBUFFERED )
		INPUT BY NAME m_url, m_add_runno, m_con_timeout, m_timeout,m_rw_timeout, m_msg,x ATTRIBUTE(WITHOUT DEFAULTS)
		END INPUT

		BEFORE DIALOG
			CALL DIALOG.setActionActive("dorequest", FALSE )
			CALL DIALOG.setActionActive("getresponse", FALSE )
			CALL DIALOG.setActionActive("getasyncresponse", FALSE )
			CALL DIALOG.setActionActive("gettextresponse", FALSE )

		ON ACTION CLOSE EXIT DIALOG
		ON ACTION back
			EXIT DIALOG

		COMMAND "Do All"
			LET x = x + 1
			CALL do_request_test("doall",DIALOG,x) RETURNING l_ret
		COMMAND "Do All x5"
			LET l_ret = TRUE
			FOR x = 1 TO 5
				IF l_ret THEN
					DISPLAY BY NAME x
					CALL do_request_test("doall",DIALOG,x) RETURNING l_ret
				END IF
			END FOR
			LET x = 0
		COMMAND "create"
			LET x = x + 1
			CALL do_request_test("create",DIALOG,x) RETURNING l_ret
		COMMAND "doRequest"
			CALL do_request_test("doRequest",DIALOG,x) RETURNING l_ret
		COMMAND "getResponse"
			CALL do_request_test("getResponse",DIALOG,x) RETURNING l_ret
		COMMAND "getAsyncResponse"
			CALL do_request_test("getAsyncResponse",DIALOG,x) RETURNING l_ret
		COMMAND "getTextResponse"
			CALL do_request_test("getTextResponse",DIALOG,x) RETURNING l_ret

	END DIALOG

	CLOSE WINDOW p14
END FUNCTION
--------------------------------------------------------------------------------
-- Get GEO Location and open it.
FUNCTION prob15()
	DEFINE l_lat, l_long FLOAT
	DEFINE l_fcstatus STRING

	OPEN WINDOW p15 WITH FORM "prob15"

	MENU
		ON ACTION get_geo
			DISPLAY "Getting Geo Location ..." TO stat
			CALL ui.interface.refresh()
			TRY
				CALL ui.Interface.frontCall("mobile", "getGeolocation", [], [l_fcstatus, l_lat, l_long])
			CATCH
				CALL fgl_winMessage("GEO Location",SFMT("Status: %1 Ret: %2\n%3",STATUS,l_fcstatus, err_get(STATUS)),"info" )
			END TRY
			CALL ui.interface.refresh()
			IF l_fcstatus = "ok" THEN
				LET m_geo_loc = SFMT("%1,%2",replace_with_dot(l_lat),replace_with_dot(l_long))
				DISPLAY SFMT("You are here: %1",m_geo_loc) TO stat
			ELSE
				DISPLAY SFMT("Failed: %1",l_fcstatus) TO stat
			END IF

		ON ACTION show_map
			IF m_geo_loc IS NOT NULL THEN
				CALL prob15_openMap( m_geo_loc )
			END IF

		ON ACTION show_map2
			CALL prob15_openMap( "51.455721,0.248923" ) -- dartford office.

		ON ACTION show_map3
			CALL prob15_openMap( "48.613363,7.711083" ) -- SXB office.

		ON ACTION close EXIT MENU
		ON ACTION accept EXIT MENU
	END MENU
	
	CLOSE WINDOW p15

END FUNCTION
--------------------------------------------------------------------------------
-- Show the location
FUNCTION prob15_openMap(l_geo)
	DEFINE l_geo STRING
	DEFINE l_prefix, l_postfix STRING
	LET l_prefix=IIF( m_cli = "GMI", "http://maps.apple.com/?ll=", "geo:")
	LET l_postfix=IIF( m_cli = "GMI", "&z=17", "?z=17")

	DISPLAY SFMT("Location: %1",l_geo) TO stat
	TRY
		CALL ui.Interface.frontCall("standard", "launchurl", [l_prefix||l_geo||l_postfix], [])
	CATCH
		CALL fgl_winMessage("Error",SFMT("FrontCall Failed: %1\n%2",STATUS,err_get(STATUS)),"info")
	END TRY
END FUNCTION
--------------------------------------------------------------------------------
-- Send an email
FUNCTION prob16()
	DEFINE l_email, l_subject, l_body STRING
	DEFINE l_ret STRING

	OPEN WINDOW p16 WITH FORM "prob16"

	LET l_email = "neilm@4js-emea.com"
	LET l_subject = "Testing Email from Mobile"
	LET l_body = "This is test email sent from "||m_cli_info
	IF m_geo_loc IS NOT NULL THEN
		LET l_body = l_body.append("\nGeo:"||m_geo_loc)
	END IF

	INPUT BY NAME l_email, l_subject, l_body WITHOUT DEFAULTS
	IF int_flag THEN
		LET int_flag = FALSE
		CLOSE WINDOW p16
		RETURN
	END IF

	TRY
		CALL ui.Interface.frontCall("mobile","composeMail",[l_email,l_subject,l_body],[l_ret])
		CALL fgl_winMessage("Email Result",SFMT("Result is %1",l_ret),"info")
	CATCH
		CALL fgl_winMessage("Error",SFMT("FrontCall Failed: %1\n%2",STATUS,err_get(STATUS)),"info")
	END TRY

	CLOSE WINDOW p16
END FUNCTION
--------------------------------------------------------------------------------
-- Various frontCalls
FUNCTION prob17()
	DEFINE l_phone, l_msg, l_res STRING
	DEFINE l_ret SMALLINT

	OPEN WINDOW p17 WITH FORM "prob17"

	MENU
		ON ACTION connectivity
			DISPLAY "Doing 'connectivity' ..." TO stat
			CALL ui.interface.refresh()
			TRY
				CALL ui.Interface.frontCall("mobile", "connectivity", [], [m_conn] )
				LET l_res = m_conn
			CATCH
				LET l_res = SFMT("FC Failed:%1 %2",STATUS,err_get(STATUS))
			END TRY
			DISPLAY BY NAME l_res

		ON ACTION composeSMS
			DISPLAY "Doing 'composeSMS' ..." TO stat
			DISPLAY "Phone No:" TO lab1
			DISPLAY "Message:" TO lab2
			LET int_flag = FALSE
			INPUT l_phone, l_msg FROM fld1, fld2
			IF NOT int_flag THEN
				TRY
					CALL ui.Interface.frontCall("mobile", "composeSMS", [l_phone,l_msg], [l_ret] )
					LET l_res = NVL(l_ret,"NULL")
				CATCH
					LET l_res = SFMT("FC Failed:%1 %2",STATUS,err_get(STATUS))
				END TRY
				DISPLAY BY NAME l_res
			END IF

		ON ACTION close EXIT MENU
		ON ACTION accept EXIT MENU
	END MENU
	
	CLOSE WINDOW p17
END FUNCTION
--------------------------------------------------------------------------------
-- Widgets
FUNCTION prob18()
  TYPE t_rec RECORD
    num SMALLINT,
    edt CHAR(20),
    edt2 CHAR(20),
    cmb STRING,
    dte DATE,
		tim DATETIME HOUR TO SECOND,
    dtetim DATETIME YEAR TO SECOND,
    chk BOOLEAN,
    radio SMALLINT,
    spin SMALLINT,
    txt STRING
  END RECORD
  DEFINE rec, sav_rec t_rec
  DEFINE audit_log STRING

  OPEN WINDOW p18 WITH FORM "prob18"
  LET audit_log = "Dialog / Widget Test\n"
  LET rec.edt = "Edit field"
  LET rec.edt2 = "EDIT UPSHIFTED"
  LET rec.cmb = "i3"
  LET rec.dte = TODAY
	LET rec.tim = TIME
  LET rec.dtetim = CURRENT
  LET rec.chk = TRUE
  LET rec.spin = 0
  LET rec.txt = "text field"
  LET sav_rec.* = rec.*

  INPUT BY NAME rec.*,audit_log WITHOUT DEFAULTS ATTRIBUTES(UNBUFFERED)
    BEFORE INPUT
      CALL DIALOG.setActionActive("accept",FALSE)
      CALL DIALOG.setActionActive("dialogtouched",TRUE)

    ON ACTION dialogTouched
      DISPLAY "Touched!  dte:",rec.dte
      IF rec.* = sav_rec.* THEN
        LET audit_log = audit_log.append("Touched but nothing changed!\n")
      ELSE
        LET audit_log = audit_log.append("Touched and changed\n")
      END IF
      LET rec.* = sav_rec.* -- re-read incase someone else has changed it
      CALL DIALOG.setActionActive("dialogtouched",FALSE)
      CALL DIALOG.setActionActive("accept",TRUE)

    ON CHANGE cmb
			LET audit_log = audit_log.append( SFMT("Combo changed to %1\n",rec.cmb))

    ON CHANGE dte
      IF rec.dte > TODAY THEN
        LET audit_log = audit_log.append("Date confirm - future date\n")
        IF fgl_winQuestion("Confirm","Date in the future, confirm okay","Yes","Yes|No","question",0) = "No" THEN
          LET audit_log = audit_log.append("Future Date okay\n")
          NEXT FIELD dte
        END IF
      ELSE
        LET audit_log = audit_log.append("Date okay\n")
      END IF
--      NEXT FIELD chk

    ON CHANGE chk
      IF NOT rec.chk THEN
        LET audit_log = audit_log.append("Jump to Spinedit\n")
        NEXT FIELD spin
      END IF

    ON ACTION cancel
      LET audit_log = audit_log.append("Cancelled\n")
      LET rec.* = sav_rec.* -- put the record
      CALL DIALOG.setActionActive("dialogtouched",TRUE)
      CALL DIALOG.setActionActive("accept",FALSE)

    ON ACTION exit
      EXIT INPUT
  END INPUT

	CLOSE WINDOW p18
END FUNCTION
--------------------------------------------------------------------------------
-- Single checkbox
FUNCTION prob19()
	DEFINE l_chk BOOLEAN
	DEFINE l_text STRING
	LET l_text = "It seems to require two taps to set it."
	OPEN WINDOW p19 WITH FORM "prob19"

	LET l_chk = FALSE
	DISPLAY l_text TO text
	INPUT BY NAME l_chk WITHOUT DEFAULTS
	IF l_chk THEN
		CALL fgl_winMessage("Information","The Checkbox was Ticked","information")
	ELSE
		CALL fgl_winMessage("Information","The Checkbox was NOT Ticked","information")
	END IF

	CLOSE WINDOW p19
END FUNCTION
--------------------------------------------------------------------------------
-- FAB
FUNCTION prob20()
	DEFINE l_fld1, l_fld2 STRING

	OPEN WINDOW p20 WITH FORM "prob20"

	MENU
		ON ACTION input
			INPUT BY NAME l_fld1,l_fld2 ATTRIBUTE(UNBUFFERED,WITHOUT DEFAULTS)
				BEFORE INPUT
					CALL DIALOG.setActionActive("accept",FALSE)
				AFTER FIELD l_fld1
					IF l_fld1 IS NOT NULL THEN
						CALL DIALOG.setActionActive("accept",TRUE)
					END IF
				ON ACTION close EXIT MENU
				ON ACTION detail
					LET l_fld1 = "detail"
			END INPUT
		ON ACTION close EXIT MENU
		ON ACTION exit EXIT MENU
	END MENU

	CLOSE WINDOW p20
END FUNCTION
--------------------------------------------------------------------------------
-- RUN without waiting
FUNCTION prob22()
	RUN "fglrun emea_testcase2.42r getgps" WITHOUT WAITING
END FUNCTION
--------------------------------------------------------------------------------
-- Layouting #1 -- folder
FUNCTION prob23(l_form, l_titl)
	DEFINE l_form, l_titl STRING
	DEFINE rec RECORD
		fld1, fld2, fld3 STRING,
	 	fld4 DATE,
		fld5, fld6, fld7, fld8 STRING
	END RECORD
	DEFINE w ui.Window
	DEFINE f ui.Form
	OPEN WINDOW p23 WITH FORM l_form
	LET w = ui.Window.getCurrent()
	LET f = w.getForm()

	IF l_form = "prob23" OR l_form = "prob24" THEN
		CALL f.setElementText("p1",l_titl)
	END IF
	LET rec.fld1 = "Field 1"
	LET rec.fld2 = "Field 2"
	LET rec.fld3 = "Field 3\nit's a text edit with mulitple lines."
	LET rec.fld4 = TODAY
	LET rec.fld5 = "f5"
	LET rec.fld6 = "fld6"
	LET rec.fld7 = "Test"
	LET rec.fld8 = "This is another text edit field with a some long text in it."
	INPUT BY NAME rec.* WITHOUT DEFAULTS

	CLOSE WINDOW p23
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION prob25()
	DEFINE arr DYNAMIC ARRAY OF RECORD
		fld1 STRING,
		fld2 STRING
	END RECORD
	DEFINE x SMALLINT

	FOR x = 1 TO 10
		LET arr[x].fld1 = "This is a test"||x
		LET arr[x].fld2 = "some more info for "||x
	END FOR

	OPEN WINDOW p25 WITH FORM "prob25" ATTRIBUTE(TYPE=LEFT)
	OPEN WINDOW p25r WITH FORM "prob25r" ATTRIBUTE(TYPE=RIGHT)
	CURRENT WINDOW IS p25

	DISPLAY ARRAY arr TO arr.*
		BEFORE ROW
			CURRENT WINDOW IS p25r
			DISPLAY arr[ arr_curr() ].fld1 TO row
			CURRENT WINDOW IS p25
	END DISPLAY

	CLOSE WINDOW p25r
	CLOSE WINDOW p25

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION prob26()
	DEFINE l_msg STRING
	DEFINE l_dbname STRING
	DEFINE l_ok INTEGER
	DEFINE l_rows SMALLINT
	OPEN WINDOW p26 WITH FORM "prob26"

	LET l_dbname = "testdb.db"
	DISPLAY base.Application.getProgramDir() TO progdir
	DISPLAY os.path.pwd() TO rundir
	DISPLAY BY NAME l_dbname
	MENU
		ON ACTION opendb
			CALL lib_db.openDB(l_dbname, TRUE) RETURNING l_ok, l_msg
			DISPLAY BY NAME l_ok
			DISPLAY BY NAME l_msg
		ON ACTION row_cnt
			LET l_rows = lib_db.test_row_cnt()
			DISPLAY BY NAME l_rows
		ON ACTION close EXIT MENU
	END MENU

	CLOSE WINDOW p26
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION prob27()
 	DEFINE l_name,l_signature STRING

	OPEN WINDOW p27 WITH FORM "prob27"

  LET int_flag = FALSE
 	INPUT BY NAME l_name, l_signature ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS=TRUE)

	CLOSE WINDOW p27
END FUNCTION
--------------------------------------------------------------------------------








--------------------------------------------------------------------------------
FUNCTION do_request_test(l_which, d,x)
	DEFINE l_which STRING
 	DEFINE l_ret BOOLEAN
	DEFINE x SMALLINT
	DEFINE d ui.Dialog

	CASE l_which
		WHEN "doall"
			CALL do_request_test("create",d,x) RETURNING l_ret
			IF m_done_cre THEN
				CALL do_request_test("doRequest",d,x) RETURNING l_ret
				IF m_done_req AND NOT m_done_res THEN
					CALL do_request_test("getResponse",d,x) RETURNING l_ret
					IF m_done_res AND m_res IS NOT NULL THEN
						CALL do_request_test("getTextResponse",d,x) RETURNING l_ret
					END IF
				END IF
			END IF
			LET m_done_cre = FALSE
			LET m_done_req = FALSE
			LET m_done_res = FALSE
			CALL d.setActionActive("create", TRUE )
			CALL d.setActionActive("dorequest", FALSE )
			CALL d.setActionActive("getresponse", FALSE )
			CALL d.setActionActive("getasyncresponse", FALSE )
			CALL d.setActionActive("gettextresponse", FALSE )
			RETURN l_ret
		WHEN "create"
			LET m_cmd = "Start Run:",x
			LET m_msg = ""
			LET m_req = NULL
			LET m_res = NULL
			LET m_done_cre = FALSE
			LET m_done_req = FALSE
			LET m_done_res = FALSE
			IF m_add_runno THEN
				LET m_url = m_url.append("&runno="||x||"&cliver="||c_appver)
			END IF
			CALL set_cmd( "\ncreate:"||m_url||" ..." )
			TRY
				LET m_req = com.HTTPRequest.Create(m_url)
				CALL set_cmd( " Ok" )
			CATCH
				CALL set_cmd( " fail:"||err_get(STATUS) )
				RETURN FALSE
			END TRY

			CALL set_cmd( "\nsetHeader:"||m_content||" ..." )
			TRY
				CALL m_req.setHeader("content-type",m_content)
				CALL set_cmd( " Ok" )
			CATCH
				CALL set_cmd( " fail:"||err_get(STATUS) )
				RETURN FALSE
			END TRY

			CALL set_cmd( "\nsetConnectionTimeOut:"||m_con_timeout||" ..." )
			TRY
				CALL m_req.setConnectionTimeOut( m_con_timeout )
				CALL set_cmd( " Ok" )
			CATCH
				CALL set_cmd( " fail:"||err_get(STATUS) )
				RETURN FALSE
			END TRY

			CALL set_cmd( "\nsetTimeOut:"||m_timeout||" ..." )
			TRY
				CALL m_req.setTimeOut( m_timeout )
				CALL set_cmd( " Ok" )
			CATCH
				CALL set_cmd( " fail"||err_get(STATUS) )
				RETURN FALSE
			END TRY

			CALL set_cmd( "\nreadwritetimeout:"||m_rw_timeout||" ..." )
			TRY
				CALL com.WebServiceEngine.SetOption( "readwritetimeout", m_rw_timeout )
				CALL set_cmd( " Ok" )
			CATCH
				CALL set_cmd( " fail:"||err_get(STATUS) )
				RETURN FALSE
			END TRY

			LET m_done_cre = TRUE
			CALL d.setActionActive("create", FALSE )
			CALL d.setActionActive("dorequest", TRUE )

		WHEN "doRequest"
			IF m_done_cre THEN
				TRY
					CALL set_cmd( "\ndoRequest ..." )
					CALL m_req.doRequest()
					LET m_done_req = TRUE
					CALL set_cmd( " Ok" )
					CALL d.setActionActive("dorequest", FALSE )
					CALL d.setActionActive("getresponse", TRUE )
					CALL d.setActionActive("getasyncresponse", TRUE )
				CATCH
					CALL set_cmd( " fail:"||err_get(STATUS) )
					RETURN FALSE
				END TRY
			END IF

		WHEN "getResponse"
			IF m_done_req AND NOT m_done_res THEN
				TRY
					CALL set_cmd( "\ngetResponse ..." )
					LET m_res = m_req.getResponse()
					CALL set_cmd( " Ok" )
					LET m_done_res = TRUE
					CALL d.setActionActive("getresponse", FALSE )
					CALL d.setActionActive("gettextresponse", TRUE )
					CALL d.setActionActive("getasyncresponse", FALSE )
				CATCH
					CALL set_cmd( " fail:"||err_get(STATUS) )
					RETURN FALSE
				END TRY
			END IF

		WHEN "getAsyncResponse"
			CALL d.setActionActive("getresponse", FALSE )
			IF m_done_req AND NOT m_done_res THEN
				TRY
					CALL set_cmd( "\ngetAsyncResponse ..." )
					LET m_res = m_req.getAsyncResponse()
					IF m_res IS NULL THEN
						CALL set_cmd( "getAsyncResponse No Response Yet, You can try again" ) 
					ELSE
						CALL set_cmd( " Ok" )
						LET m_done_res = TRUE
						CALL d.setActionActive("gettextresponse", TRUE )
						CALL d.setActionActive("getasyncresponse", FALSE )
					END IF
				CATCH
					CALL set_cmd( " fail:"||err_get(STATUS) )
					RETURN FALSE
				END TRY
			END IF
		WHEN "getTextResponse"
			IF m_done_res AND m_res IS NOT NULL THEN
				TRY
					CALL set_cmd( "\ngetTextResponse ..." )
					LET m_msg = m_res.getTextResponse()
					CALL set_cmd( " Ok" )
				CATCH
					CALL set_cmd( " fail:"||err_get(STATUS) )
					RETURN FALSE
				END TRY
			END IF
			CALL d.setActionActive("gettextresponse", FALSE )
			CALL set_cmd( "\nCompleted." )
	END CASE

	RETURN TRUE

END FUNCTION
--------------------------------------------------------------------------------
FUNCTION set_cmd(l_cmd)
	DEFINE l_cmd STRING
	DEFINE l_ts DATETIME HOUR TO FRACTION(3)
	LET l_ts = CURRENT
	CALL log(l_cmd)
	IF l_cmd.getCharAt(1) = "\n" THEN
		LET m_cmd = m_cmd.append(l_cmd)
	ELSE
		LET m_cmd = m_cmd.append(l_cmd||"("||l_ts||")")
	END IF
	DISPLAY BY NAME m_cmd
	CALL ui.interface.refresh()
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION log(l_msg)
	DEFINE l_msg STRING
	DEFINE c base.Channel
	DEFINE l_file STRING
	DISPLAY l_msg
	LET l_file = os.path.join( m_dir,base.Application.getProgramName()||".log")
	LET c = base.Channel.create()
	TRY
		CALL c.openFile(l_file,"a+")
		IF l_msg.getCharAt(1) = "\n" THEN
			LET l_msg = l_msg.subString(2,l_msg.getLength())
		END IF
		CALL c.writeLine(CURRENT||":"||l_msg)
		CALL c.close()
	CATCH
		CALL fgl_winMessage("Error",SFMT("Failed to update log file\n%1",l_file),"exclamation")
	END TRY
END FUNCTION
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- set writing a simple file.
FUNCTION write_test( l_path )
	DEFINE l_path, l_msg, l_file STRING
	DEFINE c base.Channel
	LET c = base.Channel.create()
	LET l_file = SFMT("test-%1.txt",ui.Interface.getFrontEndVersion())
	TRY
		CALL c.openFile( os.path.join( l_path,l_file), "w")
		CALL c.writeLine( "Test Running:"||CURRENT )
		CALL c.close()
		LET l_msg = SFMT("Test file %1 written okay.\n",l_file)
	CATCH
		LET l_msg = SFMT("Failed to write to %1 Status:%2\n  %3\n",l_file, STATUS, ERR_GET(STATUS))
	END TRY
	RETURN l_msg
END FUNCTION
--------------------------------------------------------------------------------
-- Set a Property in the AUI
FUNCTION deCode( data )
	DEFINE data STRING
	DEFINE t, g DECIMAL(14,10)
	DEFINE x SMALLINT
	LET x = data.getIndexOf(",",2)
	LET t = data.subString(2,x-1)
	LET g = data.subString(x+1,data.getLength()-1)
	RETURN t,g
END FUNCTION
--------------------------------------------------------------------------------
-- Set a Property in the AUI
FUNCTION wc_setProp(prop_name, value)
	DEFINE prop_name, VALUE STRING
	DEFINE w ui.Window
	DEFINE n om.domNode
	LET w = ui.Window.getCurrent()
	LET n = w.findNode("Property",prop_name)
	IF n IS NULL THEN
		DISPLAY "can't find property:",prop_name
		RETURN
	END IF
	CALL n.setAttribute("value",value)
END FUNCTION
--------------------------------------------------------------------------------
-- Replace a dot with current decimal separator
FUNCTION replace_with_dot(l_floatstr)
	DEFINE l_floatstr STRING
	DEFINE buf base.StringBuffer
	LET buf=base.StringBuffer.create()
	CALL buf.append(l_floatstr)
	CALL buf.replace(get_decimal_separator(),".",1)
	RETURN buf.toString()
END FUNCTION
--------------------------------------------------------------------------------
-- Get the deicmal separator
FUNCTION get_decimal_separator()
	DEFINE f FLOAT
	DEFINE s STRING
	LET f=1.2
	LET s=f
	RETURN s.getCharAt(2)
END FUNCTION
--------------------------------------------------------------------------------
-- called by WHENEVER ERROR CALL
FUNCTION erro()
	CALL fgl_winMessage("Error", STATUS||" "||ERR_GET( STATUS ),"exclamation")
END FUNCTION