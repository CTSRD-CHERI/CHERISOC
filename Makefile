#-
# Copyright (c) 2018 Alexandre Joannou
# All rights reserved.
#
# This software was developed by SRI International and the University of
# Cambridge Computer Laboratory (Department of Computer Science and
# Technology) under DARPA contract HR0011-18-C-0016 ("ECATS"), as part of the
# DARPA SSITH research programme.
#
# @BERI_LICENSE_HEADER_START@
#
# Licensed to BERI Open Systems C.I.C. (BERI) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  BERI licenses this
# file to you under the BERI Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.beri-open-systems.org/legal/license-1-0.txt
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @BERI_LICENSE_HEADER_END@
#

BSC = bsc

BLUESTUFFDIR = TagController/BlueStuff
BLUEUTILSDIR = $(BLUESTUFFDIR)/BlueUtils
BLUEBASICSDIR = $(BLUESTUFFDIR)/BlueBasics
PISMDIR = PISM
PISMSRCDIR = $(PISMDIR)/src
TAGCTRLSRCDIR = TagController/TagController
BSVPATH = +:$(PISMSRCDIR):$(TAGCTRLSRCDIR):$(TAGCTRLSRCDIR)/CacheCore:$(BLUESTUFFDIR):$(BLUESTUFFDIR)/AXI:$(BLUEUTILSDIR):$(BLUEBASICSDIR):%/Libraries/TLM3:%/Libraries/Axi

BSCFLAGS = -p $(BSVPATH)

# generated files directories
BUILDDIR = build
BDIR = $(BUILDDIR)/bdir
SIMDIR = $(BUILDDIR)/simdir

OUTPUTDIR = output

BSCFLAGS += -bdir $(BDIR)

BSCFLAGS += -show-schedule
BSCFLAGS += -sched-dot
BSCFLAGS += -show-range-conflict
#BSCFLAGS += -show-rule-rel \* \*
#BSCFLAGS += -steps-warn-interval n
BSCFLAGS += -D MEM128
BSCFLAGS += -D CAP128
BSCFLAGS += -D BLUESIM

# Bluespec is not compatible with gcc > 4.9
# This is actually problematic when using $test$plusargs
CC = gcc-4.8
CXX = g++-4.8

all: top_test

pism:
	$(MAKE) -C $(PISMDIR) pism
	ln -fs $(PISMSRCDIR)/pismdev/libpism.so
	ln -fs $(PISMSRCDIR)/pismdev/dram.so
	ln -fs $(PISMSRCDIR)/pismdev/ethercap.so
	ln -fs $(PISMSRCDIR)/pismdev/uart.so
	ln -fs $(PISMSRCDIR)/pismdev/fb.so
	ln -fs $(PISMSRCDIR)/pismdev/sdcard.so
	ln -fs $(PISMSRCDIR)/pismdev/virtio_block.so

top_test: Top_test.bsv pism
	mkdir -p $(OUTPUTDIR)/$@-info $(BDIR) $(SIMDIR)
	$(BSC) -info-dir $(OUTPUTDIR)/$@-info -simdir $(SIMDIR) $(BSCFLAGS) -sim -g top -u $<
	CC=$(CC) CXX=$(CXX) $(BSC) -simdir $(SIMDIR) $(BSCFLAGS) -L . -l pism -sim -e top -o $(OUTPUTDIR)/$@
	ln -fs $(PISMDIR)/memoryconfig

.PHONY: clean mrproper clean-pism

clean-pism:
	$(MAKE) -C $(PISMDIR) clean
	rm -f libpism.so
	rm -f dram.so
	rm -f ethercap.so
	rm -f uart.so
	rm -f fb.so
	rm -f sdcard.so
	rm -f virtio_block.so

clean: clean-pism
	rm -f memoryconfig
	rm -f -r $(BUILDDIR)

mrproper: clean
	rm -f -r $(OUTPUTDIR)
