
--------------------------------------------------------------------------------
FUNCTION getgps()
	DEFINE l_lat, l_long FLOAT
	DEFINE l_fcstatus STRING
	CALL ui.Interface.frontCall("mobile", "getGeolocation", [], [l_fcstatus, l_lat, l_long])
END FUNCTION