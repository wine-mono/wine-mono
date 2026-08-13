
.SUFFIXES: #disable all builtin rules

# configuration
SRCDIR:=$(dir $(MAKEFILE_LIST))
BUILDDIR=$(SRCDIR)/build
IMAGEDIR=$(SRCDIR)/image

OUTDIR=$(SRCDIR)

TESTS_OUTDIR=$(OUTDIR)/tests

WINE=wine

COMPRESSOR=xz -9 -T0
COMPRESSED_SUFFIX=xz

ENABLE_DOTNET_CORE_WINFORMS=1
ENABLE_DOTNET_CORE_WPF=1
ENABLE_DOTNET_CORE_WPFGFX=1
ENABLE_MONODX=1

ENABLE_DEBUG_SYMBOLS=1
PREFER_DWARF_SYMBOLS=0

-include user-config.make

MSI_VERSION=11.3.0

# variables
SRCDIR_ABS=$(shell cd $(SRCDIR); pwd)
BUILDDIR_ABS=$(shell cd $(BUILDDIR); pwd)
IMAGEDIR_ABS=$(shell cd $(IMAGEDIR); pwd)
IMAGEDIR_arm64_ABS=$(shell cd $(IMAGEDIR_arm64); pwd)
IMAGEDIR_x86_64_ABS=$(shell cd $(IMAGEDIR_x86_64); pwd)
OUTDIR_ABS=$(shell cd $(OUTDIR); pwd)

ARCH:=$(shell uname -m)
ifeq ($(ARCH),aarch64)
IMAGEDIR_arm64:=$(IMAGEDIR)
IMAGEDIR_x86_64:=$(SRCDIR)/image-x86_64
NATIVE_arm64=1
NATIVE_arm64ec=1
NATIVE_x86=1
else
IMAGEDIR_arm64:=$(SRCDIR)/image-arm64
IMAGEDIR_x86_64:=$(IMAGEDIR)
NATIVE_x86_64=1
NATIVE_x86=1
endif

MONO_BIN_PATH=$(BUILDDIR_ABS)/mono-unix-install/bin
MONO_LD_PATH=$(BUILDDIR_ABS)/mono-unix-install/lib
MONO_GAC_PREFIX=$(BUILDDIR_ABS)/mono-unix-install
MONO_CFG_DIR=$(BUILDDIR_ABS)/mono-unix-install/etc
MONO_ENV=PATH="$(MONO_BIN_PATH):$$PATH" LD_LIBRARY_PATH="$(MONO_LD_PATH):$$LD_LIBRARY_PATH" MONO_GAC_PREFIX="$(MONO_GAC_PREFIX)" MONO_CFG_DIR="$(MONO_CFG_DIR)"

MINGW_ENV=$(and $(MINGW_PATH),PATH=$(MINGW_PATH):$$PATH)
LLVM_MINGW_ENV=$(and $(LLVM_MINGW_PATH),PATH=$(LLVM_MINGW_PATH):$$PATH)

CP_R=$(SRCDIR_ABS)/tools/copy_recursive.py
RM_F=rm -f

# dependency checks - disabled for now because we may be using a container
# ifeq (,$(shell which $(WINE)))
# $(error '$(WINE)' command not found. Please install wine or specify its location in the WINE variable)
# endif

all: image-x86_64 image-arm64 bin-x86_64 bin-arm64 msi-x86_64 msi-arm64 tests tests-zip dbgsym-x86_64 dbgsym-arm64
.PHONY: all clean imagedir-targets imagedir-targets-x86 imagedir-targets-x86_64 imagedir-targets-arm imagedir-targets-arm64 tests tests-zip dbgsym

define HELP_TEXT =
The following targets are defined:
	msi:          Build wine-mono-$(MSI_VERSION)-x86.msi
	bin:          Build wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX)
	tests:        Build the mono tests.
	test:         Build and run the mono tests.
	dev:          Build the runtime locally in image/ and configure $$WINEPREFIX to use it.
	System.dll:   Build a single dll and place it in the image/ directory.
	image:        Build the runtime locally image/ directory.
	dev-setup:    Configure $$WINEPREFIX to use the image/ directory.
	podman-*:     Run another target inside a podman container.
endef

define newline =


endef

help:
	@echo -e '$(subst $(newline),\n,$(call HELP_TEXT))'

include llvm.make

dev-setup: build/x86/removeuserinstalls-x86.exe
	$(WINE) build/x86/removeuserinstalls-x86.exe -a
	$(WINE) msiexec /i '$(shell $(WINE) winepath -w $(IMAGEDIR)/support/winemono-support.msi)'
	$(WINE) reg add 'HKCU\Software\Wine\Mono' /v RuntimePath /d '$(shell $(WINE) winepath -w $(IMAGEDIR))' /f

dev: image
	+$(MAKE) dev-setup

$(BUILDDIR)/.dir:
	mkdir -p $(BUILDDIR)
	touch $(BUILDDIR)/.dir

clean-build:
	rm -f $(BUILDDIR)/.dir
	-rmdir $(BUILDDIR)
clean: clean-build
.PHONY: clean-build

# mingw targets
define MINGW_TEMPLATE =

ifeq (1,$(ENABLE_DEBUG_SYMBOLS))
  ifeq (1,$(PREFER_DWARF_SYMBOLS))
INSTALL_PE_$(1)=do_install () { $$(MINGW_ENV) $$(MINGW_$(1))-objcopy --only-keep-debug "$$$$1" "$$$$(printf %s "$$$$2"|sed -e 's/\....$$$$/.dbg/')"; $$(MINGW_ENV) $$(MINGW_$(1))-objcopy --strip-all "$$$$1" "$$$$2"; $$(MINGW_ENV) $$(MINGW_$(1))-objcopy --add-gnu-debuglink="$$$$(printf %s "$$$$2"|sed -e 's/\....$$$$/.dbg/')" "$$$$2"; tools/mark-wine-builtin.sh "$$$$2"; }; do_install
PDB_CFLAGS_$(1)=-gdwarf-4 -g
PDB_LDFLAGS_$(1)=
  else
INSTALL_PE_$(1)=do_install () { cp "$$$$(printf %s "$$$$1"|sed -e 's/\....$$$$/.pdb/')" "$$$$(printf %s "$$$$2"|sed -e 's/\....$$$$/.pdb/')"; cp "$$$$1" "$$$$2"; $$(MINGW_ENV) $$(MINGW_$(1))-strip "$$$$2"; tools/mark-wine-builtin.sh "$$$$2"; }; do_install
PDB_CFLAGS_$(1)=-gcodeview -g
PDB_LDFLAGS_$(1)=-Wl,-pdb=
  endif
else
INSTALL_PE_$(1)=do_install () { cp "$$$$1" "$$$$2"; $$(MINGW_ENV) $$(MINGW_$(1))-strip "$$$$2"; tools/mark-wine-builtin.sh "$$$$2"; }; do_install
endif

$$(BUILDDIR)/$(1)/.dir:
	mkdir -p $$(@D)
	touch $$@
clean-build-$(1):
	rm -f $$(BUILDDIR)/$(1)/.dir
	-rmdir $$(BUILDDIR)/$(1)
.PHONY: clean-build-$(1)
clean-build: clean-build-$(1)

# installinf.exe
$$(BUILDDIR)/$(1)/installinf-$(2).exe: $$(SRCDIR)/tools/installinf/installinf.c $$(MINGW_DEPS) $$(BUILDDIR)/$(1)/.dir
	$$(MINGW_ENV) $$(MINGW_$(1))-gcc $$< -lsetupapi -municode -mwindows -o $$@ $$(PDB_CFLAGS_$(1)) $$(PDB_LDFLAGS_$(1))

support-installinf-$(1): $$(BUILDDIR)/$(1)/installinf-$(2).exe
	mkdir -p $$(IMAGEDIR)/support/
	$$(INSTALL_PE_$(1)) $$(BUILDDIR)/$(1)/installinf-$(2).exe $$(IMAGEDIR)/support/installinf-$(2).exe
.PHONY: support-installinf-$(1)
imagedir-targets-$(1): support-installinf-$(1)
IMAGEDIR_BUILD_TARGETS_$(1) += $$(BUILDDIR)/$(1)/installinf-$(2).exe

clean-build-installinf-$(1):
	rm -rf $$(BUILDDIR)/$(1)/installinf-$(2).exe
.PHONY: clean-build-installinf-$(1)
clean-build-$(1): clean-build-installinf-$(1)

# removeuserinstalls.exe
$$(BUILDDIR)/$(1)/removeuserinstalls-$(2).exe: $$(SRCDIR)/tools/removeuserinstalls/removeuserinstalls.c $$(MINGW_DEPS) $$(BUILDDIR)/$(1)/.dir
	$$(MINGW_ENV) $$(MINGW_$(1))-gcc $$< -lmsi -lole32 -municode -mwindows -o $$@ $$(PDB_CFLAGS_$(1)) $$(PDB_LDFLAGS_$(1))

support-removeuserinstalls-$(1): $$(BUILDDIR)/$(1)/removeuserinstalls-$(2).exe
	mkdir -p $$(IMAGEDIR)/support/
	$$(INSTALL_PE_$(1)) $$(BUILDDIR)/$(1)/removeuserinstalls-$(2).exe $$(IMAGEDIR)/support/removeuserinstalls-$(2).exe
.PHONY: support-removeuserinstalls-$(1)
imagedir-targets-$(1): support-removeuserinstalls-$(1)
IMAGEDIR_BUILD_TARGETS_$(1) += $$(BUILDDIR)/$(1)/removeuserinstalls-$(2).exe

clean-build-removeuserinstalls-$(1):
	rm -rf $$(BUILDDIR)/$(1)/removeuserinstalls-$(2).exe
.PHONY: clean-build-removeuserinstalls-$(2)
clean-build-$(1): clean-build-removeuserinstalls-$(1)

# createlinks.exe
$$(BUILDDIR)/$(1)/createlinks-$(2).dll: $$(SRCDIR)/tools/createlinks/createlinks.c $$(MINGW_DEPS) $$(BUILDDIR)/$(1)/.dir
	$$(MINGW_ENV) $$(MINGW_$(1))-gcc $$< -lmsi -shared -municode -mwindows -L$$(BUILDDIR) -o $$@ $$(PDB_CFLAGS_$(1)) $$(PDB_LDFLAGS_$(1))

support-createlinks-$(1): $$(BUILDDIR)/$(1)/createlinks-$(2).dll
	mkdir -p $$(IMAGEDIR)/support/
	$$(INSTALL_PE_$(1)) $$(BUILDDIR)/$(1)/createlinks-$(2).dll $$(IMAGEDIR)/support/createlinks-$(2).dll
.PHONY: support-createlinks-$(1)
imagedir-targets-$(1): support-createlinks-$(1)
IMAGEDIR_BUILD_TARGETS_$(1) += $$(BUILDDIR)/$(1)/createlinks-$(2).dll

clean-build-createlinks-$(1):
	rm -rf $$(BUILDDIR)/$(1)/createlinks-$(2).dll
.PHONY: clean-build-createlinks-$(1)
clean-build-$(1): clean-build-createlinks-$(1)

endef

include mono.make
include fna.make
include fna3d.make
include faudio.make
include sdl3.make
include fnamf.make
include winforms.make
include winforms-datavisualization.make
include directoryservices-accountmanagement.make
include wpf.make
include monodx.make
include system-speech.make
include support.make

include tools/tests/tests.make

$(eval $(call MINGW_TEMPLATE,x86,x86))
$(eval $(call MINGW_TEMPLATE,x86_64,x86_64))
$(eval $(call MINGW_TEMPLATE,arm,arm))
$(eval $(call MINGW_TEMPLATE,arm64,arm64))
$(eval $(call MINGW_TEMPLATE,arm64ec,x86_64))

include podman.make

$(BUILDDIR)/fixuparch.exe: $(SRCDIR)/tools/fixuparch.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc $< -out:$@ -r:$(BUILDDIR)/mono-unix-install/lib/mono/gac/Mono.Cecil/0.11.1.0__0738eb9f132ed756/Mono.Cecil.dll

clean-build-fixuparch:
	rm -rf $(BUILDDIR)/fixuparch.exe
.PHONY: clean-build-fixuparch
clean-build: clean-build-fixuparch

$(BUILDDIR)/run-tests.exe: $(SRCDIR)/tools/run-tests/run-tests.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc $(SRCDIR)/tools/run-tests/run-tests.cs -out:$(BUILDDIR)/run-tests.exe

clean-build-runtestsexe:
	rm -rf $(BUILDDIR)/run-tests.exe
.PHONY: clean-build-runtestsexe
clean-build: clean-build-runtestsexe

tests: $(BUILDDIR)/run-tests.exe
	-mkdir -p $(TESTS_OUTDIR)
	cp $(BUILDDIR)/run-tests.exe $(TESTS_OUTDIR)/run-tests.exe
	cp $(SRCDIR)/tools/run-tests/*.txt $(TESTS_OUTDIR)/
.PHONY: tests

clean-tests-runtestsexe:
	rm -rf $(TESTS_OUTDIR)/run-tests.exe $(TESTS_OUTDIR)/*.txt
.PHONY: clean-tests-runtestsexe
clean-tests: clean-tests-runtestsexe

$(OUTDIR)/wine-mono-$(MSI_VERSION)-tests.zip: tests
	rm -f wine-mono-$(MSI_VERSION)-tests.zip
	do_zip () { if which 7z; then 7z a "$$@"; elif which zip; then zip -r "$$@"; else exit 1; fi; }; cd $(OUTDIR); do_zip wine-mono-$(MSI_VERSION)-tests.zip tests/

tests-zip: $(OUTDIR)/wine-mono-$(MSI_VERSION)-tests.zip

clean-tests-zip:
	rm -rf $(OUTDIR)/wine-mono-$(MSI_VERSION)-tests.zip
.PHONY: clean-tests-zip
clean: clean-tests-zip

$(BUILDDIR)/resx2srid.exe: $(SRCDIR)/tools/resx2srid/resx2srid.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc $(SRCDIR)/tools/resx2srid/resx2srid.cs -out:$(BUILDDIR)/resx2srid.exe

clean-build-resx2srid:
	rm -rf $(BUILDDIR)/resx2srid.exe
.PHONY: clean-build-resx2srid
clean-build: clean-build-resx2srid

clean-tests:
	-rmdir $(TESTS_OUTDIR)
.PHONY: clean-tests
clean: clean-tests

test: tests image
	$(MAKE) test-nobuild

test-nobuild: build/removeuserinstalls-x86.exe
	WINEPREFIX=$(BUILDDIR_ABS)/.wine-test-prefix $(WINE) reg add 'HKCU\Software\Wine\WineDbg' /v ShowCrashDialog /t REG_DWORD /d 0 /f
	WINEPREFIX=$(BUILDDIR_ABS)/.wine-test-prefix $(MAKE) dev-setup
	$(RM_F) test-output.txt
	WINEPREFIX=$(BUILDDIR_ABS)/.wine-test-prefix $(WINE) explorer /desktop=wine-mono-test cmd /c '$(shell $(WINE) winepath -w $(TESTS_OUTDIR)/run-tests.exe) >test-output.txt 2>&1'
	! grep -q 'The following tests failed but were not in fail-list:' test-output.txt

clean-build-test-prefix:
	-WINEPREFIX=$(BUILDDIR_ABS)/.wine-test-prefix wineserver -k
	rm -rf $(BUILDDIR)/.wine-test-prefix
.PHONY: clean-build-test-prefix
clean-build: clean-build-test-prefix

$(BUILDDIR)/genfilehashes.exe: $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/tools/genfilehashes/genfilehashes.cs
	$(MONO_ENV) mcs $(SRCDIR)/tools/genfilehashes/genfilehashes.cs -out:$@ -r:WineMono.Posix

clean-genfilehashes:
	rm -rf $(BUILDDIR)/genfilehashes.exe
.PHONY: clean-genfilehashes
clean-build: clean-genfilehashes

support-fakedllsinf: $(SRCDIR)/dotnetfakedlls.inf
	mkdir -p $(IMAGEDIR)/support/
	cp $(SRCDIR)/dotnetfakedlls.inf $(IMAGEDIR)/support/
.PHONY: support-fakedllsinf
imagedir-targets: support-fakedllsinf
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/dotnetfakedlls.inf

$(BUILDDIR)/.imagedir-built-arm64: $(IMAGEDIR_BUILD_TARGETS) $(IMAGEDIR_BUILD_TARGETS_x86) $(IMAGEDIR_BUILD_TARGETS_arm64) $(IMAGEDIR_BUILD_TARGETS_arm64ec)
	rm -rf "$(IMAGEDIR_arm64)"
	+$(MAKE) IMAGEDIR="$(IMAGEDIR_arm64)" imagedir-targets imagedir-targets-x86 imagedir-targets-arm64 imagedir-targets-arm64ec
	touch "$@"
clean-imagedir-built-arm64:
	rm -f $(BUILDDIR)/.imagedir-built-arm64
.PHONY: clean-imagedir-built-arm64
clean-build: clean-imagedir-built-arm64

$(BUILDDIR)/.imagedir-built-x86_64: $(IMAGEDIR_BUILD_TARGETS) $(IMAGEDIR_BUILD_TARGETS_x86) $(IMAGEDIR_BUILD_TARGETS_x86_64)
	rm -rf "$(IMAGEDIR_x86_64)"
	+$(MAKE) IMAGEDIR="$(IMAGEDIR_x86_64)" imagedir-targets imagedir-targets-x86 imagedir-targets-x86_64
	touch "$@"
clean-imagedir-built-x86_64:
	rm -f $(BUILDDIR)/.imagedir-built-arm64
.PHONY: clean-imagedir-built-arm64
clean-build: clean-imagedir-built-arm64

ifeq ($(ARCH),aarch64)
image: image-arm64
else
image: image-x86_64
endif
.PHONY: image image-arm64 image-x86_64

image-arm64: $(BUILDDIR)/.imagedir-built-arm64
image-x86_64: $(BUILDDIR)/.imagedir-built-x86_64

clean-image-arm64:
	rm -rf "$(IMAGEDIR_arm64)"
.PHONY: clean-image-arm64
clean: clean-image-arm64

clean-image-x86_64:
	rm -rf "$(IMAGEDIR_x86_64)"
.PHONY: clean-image-x86_64
clean: clean-image-x86_64

$(BUILDDIR)/.runtimemsitables-built-arm64: $(BUILDDIR)/.imagedir-built-arm64 $(SRCDIR)/msi-tables/runtime/*.idt $(SRCDIR)/tools/build-msi-tables.sh $(BUILDDIR)/genfilehashes.exe $(SRCDIR)/GNUmakefile
	$(MONO_ENV) WHICHMSI=runtime MSI_VERSION=$(MSI_VERSION) CABFILENAME=$(BUILDDIR_ABS)/image-arm64.cab TABLEDIR=$(BUILDDIR_ABS)/msi-tables/runtime-arm64 TABLESRCDIR=$(SRCDIR_ABS)/msi-tables/runtime IMAGEDIR=$(IMAGEDIR_arm64_ABS) ROOTDIR=MONODIR CABINET='#image.cab' GENFILEHASHES=$(BUILDDIR_ABS)/genfilehashes.exe WINE=$(WINE) sh $(SRCDIR)/tools/build-msi-tables.sh
	touch $@

$(BUILDDIR)/.runtimemsitables-built-x86_64: $(BUILDDIR)/.imagedir-built-x86_64 $(SRCDIR)/msi-tables/runtime/*.idt $(SRCDIR)/tools/build-msi-tables.sh $(BUILDDIR)/genfilehashes.exe $(SRCDIR)/GNUmakefile
	$(MONO_ENV) WHICHMSI=runtime MSI_VERSION=$(MSI_VERSION) CABFILENAME=$(BUILDDIR_ABS)/image-x86_64.cab TABLEDIR=$(BUILDDIR_ABS)/msi-tables/runtime-x86_64 TABLESRCDIR=$(SRCDIR_ABS)/msi-tables/runtime IMAGEDIR=$(IMAGEDIR_x86_64_ABS) ROOTDIR=MONODIR CABINET='#image.cab' GENFILEHASHES=$(BUILDDIR_ABS)/genfilehashes.exe WINE=$(WINE) sh $(SRCDIR)/tools/build-msi-tables.sh
	touch $@

$(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi: $(BUILDDIR)/.runtimemsitables-built-x86_64
	-mkdir -p $(OUTDIR)
	rm -f "$@"
	$(WINE) winemsibuilder -i '$(shell $(WINE) winepath -w $@)' $(BUILDDIR)/msi-tables/runtime-x86_64/*.idt
	$(WINE) winemsibuilder -a '$(shell $(WINE) winepath -w $@)' image.cab '$(shell $(WINE) winepath -w $(BUILDDIR)/image-x86_64.cab)'

$(OUTDIR)/wine-mono-$(MSI_VERSION)-arm64.msi: $(BUILDDIR)/.runtimemsitables-built-arm64
	-mkdir -p $(OUTDIR)
	rm -f "$@"
	$(WINE) winemsibuilder -i '$(shell $(WINE) winepath -w $@)' $(BUILDDIR)/msi-tables/runtime-arm64/*.idt
	$(WINE) winemsibuilder -a '$(shell $(WINE) winepath -w $@)' image.cab '$(shell $(WINE) winepath -w $(BUILDDIR)/image-arm64.cab)'

clean-image-cab:
	rm -f $(BUILDDIR)/image-arm64.cab
	rm -f $(BUILDDIR)/image-x86_64.cab
	rm -f $(BUILDDIR)/.runtimemsitables-built-arm64
	rm -f $(BUILDDIR)/.runtimemsitables-built-x86_64
.PHONY: clean-image-cab
clean-build: clean-image-cab

msi-x86_64: $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi
.PHONY: msi-x86_64

msi-arm64: $(OUTDIR)/wine-mono-$(MSI_VERSION)-arm64.msi
.PHONY: msi-arm64

ifeq ($(ARCH),aarch64)
msi: msi-arm64
else
msi: msi-x86_64
endif
.PHONY: msi

clean-msi:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-arm64.msi
.PHONY: clean-msi
clean: clean-msi

$(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX): $(BUILDDIR)/.imagedir-built-x86_64
	-mkdir -p $(OUTDIR)
	cd $(IMAGEDIR_x86_64)/..; tar cf $(OUTDIR_ABS)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX) --transform 's:^$(notdir $(IMAGEDIR_x86_64_ABS)):wine-mono-$(MSI_VERSION):g' '--exclude=*.pdb' '--exclude=*.dbg' '--use-compress-program=$(COMPRESSOR)' $(notdir $(IMAGEDIR_x86_64_ABS))

$(OUTDIR)/wine-mono-$(MSI_VERSION)-arm64.tar.$(COMPRESSED_SUFFIX): $(BUILDDIR)/.imagedir-built-arm64
	-mkdir -p $(OUTDIR)
	cd $(IMAGEDIR_arm64)/..; tar cf $(OUTDIR_ABS)/wine-mono-$(MSI_VERSION)-arm64.tar.$(COMPRESSED_SUFFIX) --transform 's:^$(notdir $(IMAGEDIR_arm64_ABS)):wine-mono-$(MSI_VERSION):g' '--exclude=*.pdb' '--exclude=*.dbg' '--use-compress-program=$(COMPRESSOR)' $(notdir $(IMAGEDIR_arm64_ABS))

bin-arm64: $(OUTDIR)/wine-mono-$(MSI_VERSION)-arm64.tar.$(COMPRESSED_SUFFIX)
.PHONY: bin-arm64

bin-x86_64: $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX)
.PHONY: bin-x86_64

ifeq ($(ARCH),aarch64)
bin: bin-arm64
else
bin: bin-x86_64
endif
.PHONY: bin

targz: bin
.PHONY: targz

clean-bin:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX)
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-arm64.tar.$(COMPRESSED_SUFFIX)
.PHONY: clean-bin
clean: clean-bin

$(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym-arm64.tar.$(COMPRESSED_SUFFIX): $(BUILDDIR)/.imagedir-built-arm64
	-mkdir -p $(OUTDIR)
	cd $(IMAGEDIR)/..; find $(notdir $(IMAGEDIR_arm64_ABS)) -name '*.pdb' -o -name '*.dbg'|tar cf $(OUTDIR_ABS)/wine-mono-$(MSI_VERSION)-dbgsym-arm64.tar.$(COMPRESSED_SUFFIX) --transform 's:^$(notdir $(IMAGEDIR_arm64_ABS)):wine-mono-$(MSI_VERSION):g' -T - '--use-compress-program=$(COMPRESSOR)'

$(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym-x86.tar.$(COMPRESSED_SUFFIX): $(BUILDDIR)/.imagedir-built-x86_64
	-mkdir -p $(OUTDIR)
	cd $(IMAGEDIR)/..; find $(notdir $(IMAGEDIR_x86_64_ABS)) -name '*.pdb' -o -name '*.dbg'|tar cf $(OUTDIR_ABS)/wine-mono-$(MSI_VERSION)-dbgsym-x86.tar.$(COMPRESSED_SUFFIX) --transform 's:^$(notdir $(IMAGEDIR_x86_64_ABS)):wine-mono-$(MSI_VERSION):g' -T - '--use-compress-program=$(COMPRESSOR)'

dbgsym-arm64: $(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym-arm64.tar.$(COMPRESSED_SUFFIX)
.PHONY: dbgsym-arm64

dbgsym-x86_64: $(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym-x86.tar.$(COMPRESSED_SUFFIX)
.PHONY: dbgsym-x86_64

ifeq ($(ARCH),aarch64)
dbgsym: dbgsym-arm64
else
dbgsym: dbgsym-x86_64
endif
.PHONY: dbgsym

clean-dbgsym:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym-x86.tar.$(COMPRESSED_SUFFIX)
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym-arm64.tar.$(COMPRESSED_SUFFIX)
.PHONY: clean-dbgsym
clean: clean-dbgsym

$(OUTDIR)/wine-mono-$(MSI_VERSION)-src.tar.$(COMPRESSED_SUFFIX): $(FETCH_LLVM_MINGW)/.dir
	-mkdir -p $(OUTDIR)
	$(SRCDIR)/tools/archive.sh wine-mono-$(MSI_VERSION) $(OUTDIR_ABS) wine-mono-$(MSI_VERSION)-src $(FETCH_LLVM_MINGW_DIRECTORY)
	rm -f $@
	$(COMPRESSOR) $(OUTDIR)/wine-mono-$(MSI_VERSION)-src.tar

source: $(OUTDIR)/wine-mono-$(MSI_VERSION)-src.tar.$(COMPRESSED_SUFFIX)
.PHONY: source

clean-source:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-src.tar.$(COMPRESSED_SUFFIX)
.PHONY: clean-source
clean: clean-source

print-env:
	@echo $(MONO_ENV)
