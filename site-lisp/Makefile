# Usage: cmd> make target=NAME [XYZZYHOME=/path/to/xyzzy]

XYZZYHOME ?= $(USERPROFILE)/Dropbox/xyzzy

xyzzy ?= $(XYZZYHOME)/xyzzy.exe

cp ?= copy /y
rm ?= del /f

ifndef target
$(error target is not set)
endif

#vpath %.l  $(target)
#vpath %.lc $(target)

COMPILE.l = $(xyzzy) -q -trace -I . -l batch-byte-compile.l

.PHONY: compile test %-test install uninstall clean

default: compile

compile: $(target).lc

%.lc: %.l
	$(COMPILE.l) $<

test:
	$(xyzzy) -q -trace -I . -l test/$(target)-test.l -f run-all-tests -kill

%-test: test/%-test.l
	$(xyzzy) -q -trace -I . -load batch-test.l $<

install: $(target).lc
	$(cp) $(target).lc $(XYZZYHOME)/site-lisp

uninstall:
	$(rm) $(XYZZYHOME)/site-lisp/$(target).lc

clean:
	$(rm) $(target).lc
