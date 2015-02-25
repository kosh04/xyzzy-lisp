# Usage: cmd> make target=NAME [XYZZYHOME=%USERPROFILE%/programs/xyzzy]

ifndef target
$(error target is not set)
endif

XYZZYHOME ?= $(USERPROFILE)\Dropbox\xyzzy
export XYZZYHOME

xyzzy ?= $(XYZZYHOME)\xyzzy.exe

default: compile

.PHONY: compile test install uninstall clean

compile $(target).lc: $(target).l
compile test install uninstall clean:
	$(xyzzy) -q -trace -l batch-make.l -e '(batch-make "$@" "$(target)")'
