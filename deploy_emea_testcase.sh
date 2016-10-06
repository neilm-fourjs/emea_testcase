
GARNAME=emea_testcase
GARFILE=${GARNAME}.gar

. /opt/fourjs/gas300/envas

CFG=$FGLASDIR/etc/isv_as300.xcf

echo "Undeploy ..."
gasadmin -f $CFG --disable-archive $GARNAME
gasadmin -f $CFG --undeploy-archive $GARNAME

echo "Deploy ..."
gasadmin -f $CFG --deploy-archive $GARFILE
gasadmin -f $CFG --enable-archive $GARNAME

echo "Finished."

