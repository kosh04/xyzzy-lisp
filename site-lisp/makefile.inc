# Usage: cmd> mingw32-make -f Makefile XYZZYHOME=%USERPROFILE%\Programs\xyzzy

XYZZYHOME ?= $(USERPROFILE)\Dropbox\xyzzy

xyzzy ?= $(XYZZYHOME)\xyzzy.exe

cp ?= copy /y
rm ?= del /f

ifndef target
$(error target is not set)
endif

ifndef xyzzy
$(error xyzzy is not set)
endif

default: compile

.PHONY: compile
compile $(target).lc: $(target).l
	$(xyzzy) -q -trace -e '(compile-file "$(target).l")' -kill

.PHONY: install
install: $(target).lc
	$(cp) $(target).lc $(XYZZYHOME)\site-lisp

.PHONY: uninstall
uninstall:
	$(rm) $(XYZZYHOME)\site-lisp\$(target).lc

.PHONY: test
test:
	$(xyzzy) -q -trace -I .. -l $(target)-test.l -f run-tests

.PHONY: clean
clean:
	$(rm) $(target).lc

