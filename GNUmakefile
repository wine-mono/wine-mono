
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

ENABLE_ARM64=0
ENABLE_ARM=0

-include user-config.make

MSI_VERSION=11.0.0

# variables
SRCDIR_ABS=$(shell cd $(SRCDIR); pwd)
BUILDDIR_ABS=$(shell cd $(BUILDDIR); pwd)
IMAGEDIR_ABS=$(shell cd $(IMAGEDIR); pwd)
OUTDIR_ABS=$(shell cd $(OUTDIR); pwd)

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

all: image targz msi tests tests-zip dbgsym
.PHONY: all clean imagedir-targets tests tests-zip dbgsym

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

dev-setup: build/removeuserinstalls-x86.exe
	$(WINE) build/removeuserinstalls-x86.exe -a
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

# installinf.exe
$$(BUILDDIR)/installinf-$(1).exe: $$(SRCDIR)/tools/installinf/installinf.c $$(MINGW_DEPS)
	$$(MINGW_ENV) $$(MINGW_$(1))-gcc $$< -lsetupapi -municode -mwindows -o $$@ $$(PDB_CFLAGS_$(1)) $$(PDB_LDFLAGS_$(1))

support-installinf-$(1): $$(BUILDDIR)/installinf-$(1).exe
	mkdir -p $$(IMAGEDIR)/support/
	$$(INSTALL_PE_$(1)) $$(BUILDDIR)/installinf-$(1).exe $$(IMAGEDIR)/support/installinf-$(1).exe
.PHONY: support-installinf-$(1)
imagedir-targets: support-installinf-$(1)
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/installinf-$(1).exe

clean-build-installinf-$(1):
	rm -rf $$(BUILDDIR)/installinf-$(1).exe
.PHONY: clean-build-installinf-$(1)
clean-build: clean-build-installinf-$(1)

# removeuserinstalls.exe
$$(BUILDDIR)/removeuserinstalls-$(1).exe: $$(SRCDIR)/tools/removeuserinstalls/removeuserinstalls.c $$(MINGW_DEPS)
	$$(MINGW_ENV) $$(MINGW_$(1))-gcc $$< -lmsi -lole32 -municode -mwindows -o $$@ $$(PDB_CFLAGS_$(1)) $$(PDB_LDFLAGS_$(1))

support-removeuserinstalls-$(1): $$(BUILDDIR)/removeuserinstalls-$(1).exe
	mkdir -p $$(IMAGEDIR)/support/
	$$(INSTALL_PE_$(1)) $$(BUILDDIR)/removeuserinstalls-$(1).exe $$(IMAGEDIR)/support/removeuserinstalls-$(1).exe
.PHONY: support-removeuserinstalls-$(1)
imagedir-targets: support-removeuserinstalls-$(1)
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/removeuserinstalls-$(1).exe

clean-build-removeuserinstalls-$(1):
	rm -rf $$(BUILDDIR)/removeuserinstalls-$(1).exe
.PHONY: clean-build-removeuserinstalls-$(1)
clean-build: clean-build-removeuserinstalls-$(1)

endef

include mono.make
include mono-basic.make
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

$(eval $(call MINGW_TEMPLATE,x86))
$(eval $(call MINGW_TEMPLATE,x86_64))

ifeq (1,$(ENABLE_ARM))
$(eval $(call MINGW_TEMPLATE,arm))
endif

ifeq (1,$(ENABLE_ARM64))
$(eval $(call MINGW_TEMPLATE,arm64))
endif

include podman.make

$(BUILDDIR)/fixupclr.exe: $(SRCDIR)/tools/fixupclr/fixupclr.c $(MINGW_DEPS)
	$(MINGW_ENV) $(MINGW_x86_64)-gcc -municode -Wall $< -o $@ $(PDB_CFLAGS_x86_64) $(PDB_LDFLAGS_x86_64)

clean-build-fixupclr:
	rm -rf $(BUILDDIR)/fixupclr.exe
.PHONY: clean-build-fixupclr
clean-build: clean-build-fixupclr

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

$(BUILDDIR)/.imagedir-built: $(IMAGEDIR_BUILD_TARGETS)
	rm -rf "$(IMAGEDIR)"
	+$(MAKE) imagedir-targets
	touch "$@"
clean-imagedir-built:
	rm -f $(BUILDDIR)/.imagedir-built
.PHONY: clean-imagedir-built
clean-build: clean-imagedir-built

image: $(BUILDDIR)/.imagedir-built
.PHONY: image

clean-image:
	rm -rf "$(IMAGEDIR)"
.PHONY: clean-image
clean: clean-image

$(BUILDDIR)/.runtimemsitables-built: $(BUILDDIR)/.imagedir-built $(SRCDIR)/msi-tables/runtime/*.idt $(SRCDIR)/tools/build-msi-tables.sh $(BUILDDIR)/genfilehashes.exe $(SRCDIR)/GNUmakefile
	$(MONO_ENV) WHICHMSI=runtime MSI_VERSION=$(MSI_VERSION) CABFILENAME=$(BUILDDIR_ABS)/image.cab TABLEDIR=$(BUILDDIR_ABS)/msi-tables/runtime TABLESRCDIR=$(SRCDIR_ABS)/msi-tables/runtime IMAGEDIR=$(IMAGEDIR_ABS) ROOTDIR=MONODIR CABINET='#image.cab' GENFILEHASHES=$(BUILDDIR_ABS)/genfilehashes.exe WINE=$(WINE) sh $(SRCDIR)/tools/build-msi-tables.sh
	touch $@

$(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi: $(BUILDDIR)/.runtimemsitables-built
	-mkdir -p $(OUTDIR)
	rm -f "$@"
	$(WINE) winemsibuilder -i '$(shell $(WINE) winepath -w $@)' $(BUILDDIR)/msi-tables/runtime/*.idt
	$(WINE) winemsibuilder -a '$(shell $(WINE) winepath -w $@)' image.cab '$(shell $(WINE) winepath -w $(BUILDDIR)/image.cab)'

clean-image-cab:
	rm -f $(BUILDDIR)/image.cab
	rm -f $(BUILDDIR)/.runtimemsitables-built
.PHONY: clean-image-cab
clean-build: clean-image-cab

msi: $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi
.PHONY: msi

clean-msi:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.msi
.PHONY: clean-msi
clean: clean-msi

$(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX): $(BUILDDIR)/.imagedir-built
	-mkdir -p $(OUTDIR)
	cd $(IMAGEDIR)/..; tar cf $(OUTDIR_ABS)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX) --transform 's:^$(notdir $(IMAGEDIR_ABS)):wine-mono-$(MSI_VERSION):g' '--exclude=*.pdb' '--exclude=*.dbg' '--use-compress-program=$(COMPRESSOR)' $(notdir $(IMAGEDIR_ABS))

bin: $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX)
.PHONY: bin

targz: bin
.PHONY: targz

clean-targz:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-x86.tar.$(COMPRESSED_SUFFIX)
.PHONY: clean-targz
clean: clean-targz

$(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym.tar.$(COMPRESSED_SUFFIX): $(BUILDDIR)/.imagedir-built
	-mkdir -p $(OUTDIR)
	cd $(IMAGEDIR)/..; find $(notdir $(IMAGEDIR_ABS)) -name '*.pdb' -o -name '*.dbg'|tar cf $(OUTDIR_ABS)/wine-mono-$(MSI_VERSION)-dbgsym.tar.$(COMPRESSED_SUFFIX) --transform 's:^$(notdir $(IMAGEDIR_ABS)):wine-mono-$(MSI_VERSION):g' -T - '--use-compress-program=$(COMPRESSOR)'

dbgsym: $(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym.tar.$(COMPRESSED_SUFFIX)
.PHONY: dbgsym

clean-dbgsym:
	rm -f $(OUTDIR)/wine-mono-$(MSI_VERSION)-dbgsym.tar.$(COMPRESSED_SUFFIX)
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
