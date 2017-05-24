IMPORT os

FUNCTION openDB( l_dbname, l_allow_create )
	DEFINE l_dbname, l_dbpath, l_sourcepath STRING
	DEFINE l_msg STRING
	DEFINE l_allow_create, l_created BOOLEAN
	LET l_dbpath = os.path.join( os.path.pwd(), l_dbname )
	LET l_created = FALSE
-- does final path db exist

-- if it's mobile then make sure the database exists
	IF base.Application.isMobile() THEN
		LET l_sourcepath = base.Application.getProgramDir()
	ELSE
		LET l_sourcepath = "../database"
	END IF
	DISPLAY "DBName:",l_dbname," Final Path:",l_dbpath, " Source Path:",l_sourcepath

	IF NOT os.path.exists( l_dbpath ) THEN
		LET l_msg = SFMT("DB %1 missing\n", l_dbpath)

--  does a local db exist at the source path
		IF os.path.exists( os.path.join(l_sourcepath,l_dbname) ) THEN
--    copy an existing db to the final db path
			IF os.path.copy( os.path.join(l_sourcepath,l_dbname), l_dbpath ) THEN
				LET l_msg = l_msg.append(SFMT("Copied from %1\n",l_sourcepath))
			ELSE
				LET l_msg = l_msg.append(SFMT("Copy DB %1 to %2 failed!\n",os.path.join(l_sourcepath,l_dbname), l_dbpath))
				RETURN FALSE, l_msg||ERR_GET(STATUS)
			END IF
		ELSE -- no source db so we create a new db
			IF l_allow_create THEN
				TRY
					CREATE DATABASE l_dbname
					LET l_msg = l_msg.append( "Created database\n" )
				CATCH
					RETURN STATUS, l_msg||SQLERRMESSAGE
				END TRY
				LET l_created = TRUE
			ELSE
				RETURN FALSE, l_msg
			END IF
		END IF
	ELSE
		LET l_msg = "Database Exists, Connecting\n"
	END IF

-- connect to final path db
	TRY
		DATABASE l_dbpath
		LET l_msg = l_msg.append("Connected okay.")
	CATCH
		RETURN FALSE, l_msg||SQLERRMESSAGE
	END TRY

	IF l_created THEN LET l_msg = l_msg.append( db_add_tables() ) END IF

	RETURN TRUE,l_msg
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


	RETURN " Tables created."
END FUNCTION
--------------------------------------------------------------------------------
FUNCTION test_row_cnt()
	DEFINE l_cnt SMALLINT
	SELECT COUNT(*) INTO l_cnt FROM tab1
	RETURN l_cnt
END FUNCTION