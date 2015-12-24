
--CONSTANT WC_PATH = "file:///opt3/gdc-2.30.04-build4007/webcomponents"
--CONSTANT WC_PATH = "file:///home/neilm/all/gwc/WebComponents"
IMPORT os
MAIN
	DEFINE lat, lat2, lng, lng2, wc_data, in_data STRING
	DEFINE l_tf BOOLEAN

	CALL ui.Interface.frontCall("standard","setwebcomponentpath", os.path.pwd(),l_tf)
	IF NOT l_tf THEN
		CALL fgl_winMessage("Error","Failed to set setwebcomponentpath!","exclamation")
		EXIT PROGRAM
	END IF

	OPEN FORM f FROM "gm"
	DISPLAY FORM f

-- Old
	LET lat = "50.8462723212"
	LET lng = "-0.2846145630"
-- New
	LET lat2 = "50.840805203"
	LET lng2 = "-0.3346055746"

	LET wc_data = "fred"

	CALL wc_setProp("lat",lat)
	CALL wc_setProp("lng",lng)

	INPUT BY NAME wc_data, lat, lng, in_data  ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
		ON ACTION go
			CALL wc_setProp("lat",lat2)
			CALL wc_setProp("lng",lng2)
		ON ACTION close EXIT INPUT
		ON ACTION mapclicked
			LET in_data = wc_data
			CALL deCode(in_data) RETURNING lat, lng
			DISPLAY "Map Clicked:", lat," ", lng
	END INPUT

END MAIN
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