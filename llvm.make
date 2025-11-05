FETCH_LLVM_MINGW_VERSION=20251104
FETCH_LLVM_MINGW_DIRECTORY=llvm-mingw-$(FETCH_LLVM_MINGW_VERSION)-ucrt-ubuntu-22.04-x86_64

FETCH_LLVM_MINGW_ARCHIVE=$(FETCH_LLVM_MINGW_DIRECTORY).tar.xz
FETCH_LLVM_MINGW_URL=https://github.com/mstorsjo/llvm-mingw/releases/download/$(FETCH_LLVM_MINGW_VERSION)/$(FETCH_LLVM_MINGW_ARCHIVE)

FETCH_LLVM_MINGW=$(SRCDIR_ABS)/$(FETCH_LLVM_MINGW_DIRECTORY)

# defaults

AUTO_LLVM_MINGW?=1

ifeq ($(origin MINGW_x86) $(origin MINGW_x86_64) $(origin LLVM_MINGW_PATH) $(AUTO_LLVM_MINGW),undefined undefined undefined 1)

#default: obtain llvm-mingw automatically

ifeq (x$(wildcard $(FETCH_LLVM_MINGW)/.dir),x)
# fetch llvm-mingw only if it doesn't exist, so we can include just the directory in tarballs
DO_FETCH_LLVM_MINGW=1
endif

LLVM_MINGW_PATH = $(FETCH_LLVM_MINGW)/bin

endif

MINGW_PATH ?= $(LLVM_MINGW_PATH)
MINGW_x86 ?= i686-w64-mingw32
MINGW_x86_64 ?= x86_64-w64-mingw32
MINGW_arm ?= armv7-w64-mingw32
MINGW_arm64 ?= aarch64-w64-mingw32

# automatically fetching and extracting llvm-mingw

$(SRCDIR)/$(FETCH_LLVM_MINGW_ARCHIVE): $(SRCDIR)/llvm.make
	wget --no-verbose '$(FETCH_LLVM_MINGW_URL)' -O $@ --no-use-server-timestamps
	touch $@

$(FETCH_LLVM_MINGW)/.dir: $(SRCDIR)/$(FETCH_LLVM_MINGW_ARCHIVE)
	cd $(SRCDIR); tar xmf $(FETCH_LLVM_MINGW_ARCHIVE)
	touch $@

ifeq ($(DO_FETCH_LLVM_MINGW),1)
MINGW_DEPS=$(FETCH_LLVM_MINGW)/.dir
else
MINGW_DEPS=$(SRCDIR)/llvm.make
endif
