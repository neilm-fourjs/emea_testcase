IMPORT os

FUNCTION openDB( l_dbname )
	DEFINE l_dbname, l_dbpath STRING
	DEFINE l_msg STRING
	DEFINE l_created BOOLEAN
	LET l_dbpath = os.path.join( os.path.pwd(), l_dbname )

	LET l_created = FALSE
-- does final path db exist
	IF NOT os.path.exists( l_dbpath ) THEN
		LET l_msg = "db missing, "
--  does a local db exist here
		IF NOT os.path.exists( l_dbname ) THEN
--    create a new local db
			TRY
				CREATE DATABASE l_dbname
				LET l_msg = l_msg.append( "created, " )
			CATCH
				RETURN STATUS, l_msg||SQLERRMESSAGE
			END TRY
			LET l_created = TRUE
		ELSE
--    copy an existing db to the final db path
			IF os.path.copy( os.path.join( base.Application.getProgramDir(),l_dbname ), os.path.pwd() ) THEN
				LET l_msg = l_msg.append("Copied ")
			ELSE
				LET l_msg = l_msg.append("Copy failed! ")
				RETURN STATUS, l_msg||ERR_GET(STATUS)
			END IF
		END IF
	ELSE
		LET l_msg = "db exists, "
	END IF

-- connect to final path db
	TRY
		DATABASE l_dbpath
		LET l_msg = l_msg.append("Connected okay")
	CATCH
		RETURN STATUS, l_msg||SQLERRMESSAGE
	END TRY

	IF l_created THEN LET l_msg = l_msg.append( db_add_tables() ) END IF

	RETURN 0,l_msg
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION db_add_tables()

	TRY
		CREATE TABLE tab1 (
			fld1 SERIAL,
			fld2 CHAR(20)
		)
	CATCH
		RETURN SQLERRMESSAGE
	END TRY

	TRY
		INSERT INTO tab1 VALUES(1,"Test Record 1")
		INSERT INTO tab1 VALUES(2,"Test Record 2")
		INSERT INTO tab1 VALUES(3,"Test Record 3")
	CATCH
		RETURN SQLERRMESSAGE
	END TRY


	RETURN "tables created. "
END FUNCTION