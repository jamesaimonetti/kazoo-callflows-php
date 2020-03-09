CWD = $(shell pwd -P)
ROOT = $(realpath $(CWD)/../..)
PROJECT = callflows_php

all: compile

include $(ROOT)/make/kz.mk
