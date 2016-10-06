
CONSTANT C_REG_PORT = 9999
--CONSTANT C_REG_URL= "http://10.2.1.199:9999"
--CONSTANT C_REG_URL= "http://10.1.0.103/g3/ws/r/regtoken"
CONSTANT C_REG_URL= "http://www.4js-emea.com/dr/ws/r/regtoken"
CONSTANT C_SENDER_ID = "960478794365"

TYPE t_reg_rec RECORD
				id INTEGER,
				sender_id VARCHAR(150),
				registration_token VARCHAR(250),
				badge_number INTEGER,
				app_user VARCHAR(50),
				app_ver DECIMAL(5,2),
				reg_date DATETIME YEAR TO SECOND,
				send BOOLEAN
		END RECORD
