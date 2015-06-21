
#TARGETS: DEFAULT, MINGW32, OSX
TARGET ?= DEFAULT

ifeq (${TARGET}, MINGW32)
	PROGRAM ?= cammill.exe
	LIBS    ?= -lm -lstdc++ -lgcc
	CROSS   ?= i686-w64-mingw32.static-
	COMP    ?= i686-w64-mingw32.static-gcc
	PKGS    ?= gtk+-2.0 gtk+-win32-2.0 gtkglext-1.0 gtksourceview-2.0 lua
	INSTALL_PATH ?= Windows/CamMill
endif

ifeq (${TARGET}, OSX)
	LIBS    ?= -framework OpenGL -framework GLUT -lm -lpthread -lstdc++ -lc
	PKGS    ?= gtk+-2.0 gtkglext-1.0 gtksourceview-2.0 lua
    PKG_CONFIG_PATH ?= /opt/X11/lib/pkgconfig
endif



COMP?=$(CROSS)clang
PKG_CONFIG=$(CROSS)pkg-config

HERSHEY_FONTS_DIR = ./
PROGRAM ?= cammill
INSTALL_PATH ?= /opt/${PROGRAM}

LIBS   ?= -lGL -lglut -lGLU -lX11 -lm -lpthread -lstdc++ -lXext -ldl -lXi -lxcb -lXau -lXdmcp -lgcc -lc
CFLAGS += -I./
CFLAGS += "-DHERSHEY_FONTS_DIR=\"./\""
CFLAGS += -ggdb -Wno-int-to-void-pointer-cast -Wall -Wno-unknown-pragmas -O3

OBJS = main.o pocket.o calc.o hersheyfont.o postprocessor.o setup.o dxf.o font.o texture.o os-hacks.o

# GTK+2.0 and LUA5.1
PKGS ?= gtk+-2.0 gtkglext-x11-1.0 gtksourceview-2.0 lua5.1
CFLAGS += "-DGDK_DISABLE_DEPRECATED -DGTK_DISABLE_DEPRECATED"
CFLAGS += "-DGSEAL_ENABLE"

# LIBG3D
#PKGS += libg3d
#CFLAGS += "-DUSE_G3D"

# VNC-1.0
#PKGS += gtk-vnc-1.0
#CFLAGS += "-DUSE_VNC"

# WEBKIT-1.0
#PKGS += webkit-1.0 
#CFLAGS += "-DUSE_WEBKIT"

ALL_LIBS = $(LIBS) $(PKGS:%=`$(PKG_CONFIG) % --libs`)
CFLAGS += $(PKGS:%=`$(PKG_CONFIG) % --cflags`)

LANGS += de
LANGS += it
LANGS += fr

PO_MKDIR = mkdir -p $(foreach PO,$(LANGS),intl/$(PO)_$(shell echo $(PO) | tr "a-z" "A-Z").UTF-8/LC_MESSAGES)
PO_MSGFMT = $(foreach PO,$(LANGS),msgfmt po/$(PO).po -o intl/$(PO)_$(shell echo $(PO) | tr "a-z" "A-Z").UTF-8/LC_MESSAGES/${PROGRAM}.mo\;)


all: lang ${PROGRAM}

lang:
	@echo ${PO_MKDIR}
	@echo ${PO_MKDIR} | sh
	@echo ${PO_MSGFMT}
	@echo ${PO_MSGFMT} | sh

${PROGRAM}: ${OBJS}
		$(COMP) -o ${PROGRAM} ${OBJS} ${ALL_LIBS} ${INCLUDES} ${CFLAGS}

%.o: %.c
		$(COMP) -c $(CFLAGS) ${INCLUDES} $< -o $@

gprof:
	gcc -pg -o ${PROGRAM} ${OBJS} ${ALL_LIBS} ${INCLUDES} ${CFLAGS}
	@echo "./${PROGRAM}"
	@echo "gprof ${PROGRAM} gmon.out"

clean:
	rm -rf ${OBJS}
	rm -rf ${PROGRAM}

install: ${PROGRAM}
	mkdir -p ${INSTALL_PATH}
	cp ${PROGRAM} ${INSTALL_PATH}/${PROGRAM}
	chmod 755 ${INSTALL_PATH}/${PROGRAM}
	mkdir -p ${INSTALL_PATH}/posts
	cp -a posts/* ${INSTALL_PATH}/posts
	mkdir -p ${INSTALL_PATH}/textures
	cp -a textures/* ${INSTALL_PATH}/textures
	mkdir -p ${INSTALL_PATH}/icons
	cp -a icons/* ${INSTALL_PATH}/icons
	mkdir -p ${INSTALL_PATH}/fonts
	cp -a fonts/* ${INSTALL_PATH}/fonts
	mkdir -p ${INSTALL_PATH}/doc
	cp -a doc/* ${INSTALL_PATH}/doc
	cp -a GPLv3.txt material.tbl postprocessor.lua tool.tbl cammill.dxf test.dxf ${INSTALL_PATH}/

win_installer:
	(cd ${INSTALL_PATH} ; tclsh ../../utils/create-win-installer.tclsh > installer.nsis)
	cp icons/icon.ico ${INSTALL_PATH}/icon.ico
	(cd ${INSTALL_PATH} ; makensis installer.nsis)
	mv ${INSTALL_PATH}/installer.exe Windows/

