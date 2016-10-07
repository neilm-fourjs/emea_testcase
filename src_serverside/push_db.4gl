
--------------------------------------------------------------------------------
FUNCTION open_create_db()
	DEFINE l_dbsrc VARCHAR(100)
	DEFINE x INTEGER

	LET l_dbsrc = "tokendb" --+driver='dbmsqt'"
	TRY
		CONNECT TO l_dbsrc
		DISPLAY "Connected to ",l_dbsrc
	CATCH
		CALL fgl_winMessage("Fatal",SFMT("Failed to connect to %1\n%2",l_dbsrc,SQLERRMESSAGE),"exclamation")
		EXIT PROGRAM
	END TRY

	WHENEVER ERROR CONTINUE
	SELECT COUNT(*) INTO x FROM tokens
	WHENEVER ERROR STOP

	IF SQLCA.SQLCODE < 0 THEN
		DISPLAY "Creating tokens table..."
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
		IF SQLCA.SQLCODE < 0 THEN
			CALL fgl_winMessage("Fatal",SFMT("Failed to create table tokens\n%1",SQLERRMESSAGE),"exclamation")
		END IF
	END IF
	DISPLAY "db okay."
END FUNCTION