all: fxs
.PHONY: all fxs clean

include $(NCS_DIR)/src/ncs/build/include.ncs.mk

SRC = $(wildcard yang/*.yang)
DIRS = ../load-dir
FXS = $(SRC:yang/%.yang=../load-dir/%.fxs)

YANGPATH += $(NCS_DIR)/src/ncs/yang
NCSCPATH = $(YANGPATH:%=--yangpath %)

fxs: $(DIRS) $(FXS)

$(DIRS):
	mkdir -p $@

../load-dir/%.fxs: yang/%.yang
	$(NCSC) --fail-on-warnings $(NCSCPATH) -c -o $@ $<

clean:
	rm -rf ../load-dir
