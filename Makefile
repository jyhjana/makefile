###########################################################################
#
# MODULE:             Eyesight - Makefile
#
# REVISION:           $Revision: 1.0 $
#
# DATED:              $Date: 2015-10-1 11:16:28 +0000 $
#
# AUTHOR:             PCT
#
###########################################################################
#
# Copyright Tonly B.V. 2015. All rights reserved
#
###########################################################################
TARGET := eyesight_daemon

.PHONY: all clean distclean depends_app test install

default:all
all: $(TARGET)

SRC_DIR := .
SOURCE := $(wildcard $(SRC_DIR)/*.cpp)
DEPENDS_APP_DIR := $(shell pwd)/DependsPackages

CFLAGS := -I./include/
PROJ_DFLAGS := -D_REENTRANT -marm -pthread
PROJ_LIBS := -L./lib
PROJ_LIBS += -lpthread -lrt -lzmq -ljson-c  ` pkg-config  --cflags --libs opencv`

CROSS_COMPILE?=arm-linux-gnueabihf-
CC=$(CROSS_COMPILE)g++
CCC=$(CROSS_COMPILE)gcc
LD=$(CROSS_COMPILE)g++

JSON_DIR = json-c-0.11
ZMQ_DIR = zeromq-4.1.5

RM ?= -rm
CFLAGS += -Wall -fsigned-char -O3 -g -mfloat-abi=hard -marm -mfpu=neon -pthread -Wno-reorder
INC := -I./ \
    -I./Interface/Constants/Inc/ \
    -I./Interface/CoreInput/Inc/ \
    -I./Interface/CoreOutput/Inc/ \
    -I./Interface/CoreStructures/Inc/

OBJS := $(patsubst %.cpp,%.o,$(SOURCE))

vpath %.cpp $(SRC_DIR)

depends_app:
	#zeromq
	if [ -d $(DEPENDS_APP_DIR)/$(ZMQ_DIR) ]; then\
		echo "Compile zeromq package";\
		cd $(DEPENDS_APP_DIR)/$(ZMQ_DIR);\
		if [ -f ./Makefile ];then\
			make distclean;\
		fi;\
		./configure --prefix=/usr;\
		cd -;\
		$(MAKE) $(DEPENDS_APP_DIR)/$(ZMQ_DIR) &&$(MAKE) $(DEPENDS_APP_DIR)/$(ZMQ_DIR) install || exit "$$?";\
	fi
	
	#json-c-0.11
	if [ -d $(DEPENDS_APP_DIR)/$(JSON_DIR) ]; then\
		echo "Compile json package";\
		cd $(DEPENDS_APP_DIR)/$(JSON_DIR);\
		if [ -f ./Makefile ];then\
			make clean;\
		fi;\
		./configure --prefix=/usr; \
		cd -;\
		$(MAKE) $(DEPENDS_APP_DIR)/$(JSON_DIR) && $(MAKE) $(DEPENDS_APP_DIR)/$(JSON_DIR) install || exit "$$?";\
	fi	
	
$(TARGET):$(OBJS) ./bin/libeyeSight.a
	@$(CC) $(PROJ_DFLAGS) $^ $(PROJ_CFLAGS) $(CFLAGS) $(INC) $(PROJ_LIBS) -o $@ 

%.o:%.cpp
	$(CC) $(PROJ_DFLAGS) $(INC) $(CFLAGS) -c $< -o $@

test:
	@echo $(SOURCE)
	@echo $(OBJS)

clean:
	$(RM) $(TARGET) $(OBJS)

install:
	sysv-rc-conf --list | grep sudo || sudo apt-get install sysv-rc-conf -y
	sudo cp $(TARGET) /usr/local/bin/
	sudo cp $(TARGET).sh /etc/init.d/
	sudo chmod +x /etc/init.d/$(TARGET).sh
	cd /etc/init.d; sudo sysv-rc-conf $(TARGET).sh on

uninstall:
	sudo /etc/init.d/$(TARGET).sh stop
	cd /etc/init.d; sudo sysv-rc-conf $(TARGET).sh off
	sudo rm /etc/init.d/$(TARGET).sh
	sudo rm /usr/local/bin/$(TARGET)
