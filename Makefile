
GARNAME=emea_testcase
GITVER=$(shell git describe --always)
GARFILE=$(GARNAME).gar

export ANDROID_HOME=/opt/Android/android-sdk-linux
export JDK_HOME=/usr/lib/jvm/java-7-oracle
export PATH+=$(JDK_HOME)/bin:$(GMATOOLSDIR):$(ANDROID_HOME)/tools:$(ANDROID_HOME)/tools/lib:$(ANDROID_HOME)/platform-tools

all: $(GARFILE)

progs:
	gsmake emea_testcase300.4pw -t resttest -t push_server -t push_register_tokens

clean:
	rm -f *.gar;
	rm -f *.4pw??;
	find . -name \*.42? -exec rm {} \;
	find . -name \*.err -exec rm {} \;
	find . -name \*.out -exec rm {} \;
	find . -name \*.rdd -exec rm {} \;
	find . -name \*.log -exec rm {} \;

$(GARFILE): clean progs MANIFEST
	$(info Building Genero Archive ...)
	@zip -qr $(GARNAME)-$(GITVER).gar MANIFEST gas/*.xcf bin_serverside/*.42? images/*.png
	ln -s $(GARNAME)-$(GITVER).gar $(GARFILE)
	$(info Done)

