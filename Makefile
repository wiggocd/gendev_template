ifndef VERBOSE
.SILENT:
endif

TOOLS := ./tools

ifeq ($(GENDEV),)
GENDEV := /opt/gendev
endif

MD_BUILD_DIRS := ${TOOLS}/data, ../build, ../bin, ../dist
export GENDEV
export MD_BUILD_DIRS

all:
	make -f ${GENDEV}/sgdk/mkfiles/makefile.gen clean all

setup:
	${TOOLS}/setup.sh --install
	${TOOLS}/setup.sh --clean

clean:
	${TOOLS}/setup.sh --clean

setup-clean:
	${TOOLS}/setup.sh --all

uninstall:
	$(TOOLS)/setup.sh --uninstall