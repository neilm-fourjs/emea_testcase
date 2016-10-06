# emea_testcase
Genero Mobile testcase program

The project is emea_testcase300.4pw for Genero 3.00

__Note:__ I've not yet tested this program with Genero 3.00 on iOS devices.

### Server side programs
* resttest - test of restful api for simple data ( resttest.42r )
* regtoken - program to register tokens for push notifications ( push_register_tokens.42r )
* sendnote - program to push a notification ( push_server.42r )

The makefile is designed to build a gar for deploying to a GAS server the 3 server programs.

### TODO:
* Test on iOS
* Add a test for sending / receiving a text file to and from server.
* Add a test for sending / receiving a binary file to and from server.
* Add some database tests
