
TEST_CS_EXE_SRCS = \
	arraypadding.cs \
	assemblysearchgacbeforepath.cs \
	configuration-with-defaults.cs \
	direct3dadapter.cs \
	dllimport-cctor.cs \
	dllimport-preload.cs \
	interactioncommand.cs \
	marshalansi.cs \
	mixedmode-apt.cs \
	mixedmode-call.cs \
	mixedmode-dllimport-0.cs \
	mixedmode-dllimport-assemblydirectory.cs \
	mixedmode-dllimport-default.cs \
	mixedmode-dllimport-usedlldirectory.cs \
	mixedmode-exe.cs \
	mixedmode-managedcaller.cs \
	mixedmode-nativedir.cs \
	mixedmode-path.cs \
	mixedmode-samedir.cs \
	ordinalimport.cs \
	privatepath1.cs \
	privatepath2.cs \
	processnames.cs \
	rcw-visible.cs \
	releasebadptr.cs \
	runtimeinterface.cs \
	seh.cs \
	system-resources.cs \
	timezonetest.cs \
	thread-exit-bk.cs \
	unmanaged-configpath.cs \
	valist.cs \
	vbstartup.cs \
	vtblgap.cs \
	xnatest.cs \
	webbrowsertest.cs \
	winemono-ccw.cs \
	wpfclipboard.cs

TEST_RAW_FILES = \
	direct3dadapter.exe.config \
	configuration-with-defaults.exe.config \
	mixedmode-managedcaller.exe.config \
	mixedmode-dllimport-0.exe.config \
	mixedmode-dllimport-assemblydirectory.exe.config \
	mixedmode-dllimport-default.exe.config \
	mixedmode-dllimport-usedlldirectory.exe.config \
	privatepath2.exe.config \
	privatepath1.exe.config

TEST_IL_EXE_SRCS = \
	marshalcopy.il

TEST_CLR_EXE_TARGETS = $(TEST_CS_EXE_SRCS:%.cs=tools/tests/%.exe) $(TEST_IL_EXE_SRCS:%.il=tools/tests/%.exe) vstests/wpfapptest/bin/Release/wpfapptest.exe

ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
TEST_NUNIT_TARGETS = \
	net_4_x_PresentationCore_test.dll
endif

TEST_INSTALL_FILES = $(TEST_RAW_FILES:%=tools/tests/%)

TEST_BINARY_FILES = \
	mixedapartmentstate.exe \
	mixedmodeexe.exe \
	mixedmodelibrary.dll \
	nativelibrary.dll

tools/tests/%.exe: tools/tests/%.il $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) ilasm -target:exe -output:$@ $<

tools/tests/%.exe: tools/tests/%.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc -unsafe -target:exe -out:$@ $(patsubst %,-r:%,$(filter %.dll,$^)) $(foreach path,$(filter %/.built,$^),-r:$(dir $(path))/$(notdir $(realpath $(dir $(path)))).dll) $< $(shell sed -n '/CSCFLAGS=/s/^.*CSCFLAGS=//p' $<)

tools/tests/%.dll: tools/tests/%.cs $(BUILDDIR)/mono-unix/.installed
	$(MONO_ENV) csc -target:library -out:$@ $(patsubst %,-r:%,$(filter %.dll,$^)) $< $(shell sed -n '/CSCFLAGS=/s/^.*CSCFLAGS=//p' $<)

tools/tests/mixedmode-managedcaller.exe: vstests/Win32/Release/mixedmodelibrary.dll

tools/tests/mixedmode-dllimport-0.exe: tools/tests/mixedmode-dllimport.dll
tools/tests/mixedmode-dllimport-assemblydirectory.exe: tools/tests/mixedmode-dllimport.dll
tools/tests/mixedmode-dllimport-default.exe: tools/tests/mixedmode-dllimport.dll
tools/tests/mixedmode-dllimport-usedlldirectory.exe: tools/tests/mixedmode-dllimport.dll

tools/tests/privatepath1.exe: tools/tests/testcslib1.dll

tools/tests/privatepath2.exe: tools/tests/testcslib1.dll tools/tests/testcslib2.dll

tools/tests/xnatest.exe: tools/tests/Microsoft.Xna.Framework.Game.dll tools/tests/Microsoft.Xna.Framework.dll

tools/tests/wpfclipboard.exe: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built

tools/tests/direct3dadapter.exe: $(SRCDIR)/monoDX/Microsoft.DirectX.Direct3D/.built

tools/tests/net_4_x_%_test.dll: $(BUILDDIR)/nunitlite.dll
	$(MONO_ENV) csc -target:library -out:$@ $(patsubst %,-r:%,$(filter %.dll,$^)) $(foreach path,$(filter %/.built,$^),-r:$(dir $(path))/$(notdir $(realpath $(dir $(path)))).dll) $(filter %.cs,$^)

tools/tests/net_4_x_PresentationCore_test.dll: \
	tools/tests/PresentationCore/TextFormatter.cs

TEST_NUNIT_EXTRADEPS_net_4_x_PresentationCore_test.dll = \
	$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built \
	$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built

define nunit_target_template
tools/tests/$(1): $$(TEST_NUNIT_EXTRADEPS_$(1))
$$(TESTS_OUTDIR)/tests-clr/$(1): $$(SRCDIR)/tools/tests/$(1) tests-clr
	mkdir -p $$(TESTS_OUTDIR)/tests-clr
	$$(MONO_ENV) MONO_PATH=$$(subst $$(eval) ,:,$$(foreach path,$$(TEST_NUNIT_EXTRADEPS_$(1)),$$(dir $$(path)))) mono $(TESTS_OUTDIR)/tests-clr/nunit-lite-console.exe $$< -explore:$$(TESTS_OUTDIR)/tests-clr/$(1).testlist && test -f $$(TESTS_OUTDIR)/tests-clr/$(1).testlist
	cp $$< $$@
tests: $$(TESTS_OUTDIR)/tests-clr/$(1)
endef

$(foreach target,$(TEST_NUNIT_TARGETS), $(eval $(call nunit_target_template,$(target))))

tools-tests-all: tools/tests/System.Windows.Forms.dll

tools-tests-all: $(TEST_CLR_EXE_TARGETS) $(TEST_INSTALL_FILES) tools/tests/tests.make
.PHONY: tools-tests-all

tools-tests-install: tools-tests-all $(BUILDDIR)/fixupclr.exe
	mkdir -p $(TESTS_OUTDIR)/tests-x86
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64
	for i in $(TEST_CLR_EXE_TARGETS); do \
		cp $$i $(TESTS_OUTDIR)/tests-x86 ; \
		$(WINE) $(BUILDDIR)/fixupclr.exe x86 $(TESTS_OUTDIR)/tests-x86/$$(basename $$i) ; \
		cp $$i $(TESTS_OUTDIR)/tests-x86_64 ; \
		$(WINE) $(BUILDDIR)/fixupclr.exe x86_64 $(TESTS_OUTDIR)/tests-x86_64/$$(basename $$i) ; \
	done
	for i in $(TEST_INSTALL_FILES); do \
		cp $$i $(TESTS_OUTDIR)/tests-x86 ; \
		cp $$i $(TESTS_OUTDIR)/tests-x86_64 ; \
	done
	mkdir -p $(TESTS_OUTDIR)/tests-x86/lib1
	cp tools/tests/testcslib1.dll $(TESTS_OUTDIR)/tests-x86/lib1
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64/lib1
	cp tools/tests/testcslib1.dll $(TESTS_OUTDIR)/tests-x86_64/lib1
	mkdir -p $(TESTS_OUTDIR)/tests-x86/lib2
	cp tools/tests/testcslib2.dll $(TESTS_OUTDIR)/tests-x86/lib2
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64/lib2
	cp tools/tests/testcslib2.dll $(TESTS_OUTDIR)/tests-x86_64/lib2
	mkdir -p $(TESTS_OUTDIR)/tests-x86/vstests
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64/vstests
	for i in $(TEST_BINARY_FILES); do \
		cp $(SRCDIR)/vstests/Win32/Release/$$i $(TESTS_OUTDIR)/tests-x86/vstests ; \
		cp $(SRCDIR)/vstests/x64/Release/$$i $(TESTS_OUTDIR)/tests-x86_64/vstests ; \
	done
	cp tools/tests/mixedmode-managedcaller.exe tools/tests/mixedmode-dllimport.dll $(TESTS_OUTDIR)/tests-x86/vstests
	$(WINE) $(BUILDDIR)/fixupclr.exe x86 $(TESTS_OUTDIR)/tests-x86/vstests/mixedmode-managedcaller.exe
	$(INSTALL_PE_x86) $(BUILDDIR)/call-mixedmode-x86.exe $(TESTS_OUTDIR)/tests-x86/vstests/call-mixedmode.exe
	$(INSTALL_PE_x86) $(BUILDDIR)/call-method-x86.exe $(TESTS_OUTDIR)/tests-x86/vstests/call-method.exe
	cp tools/tests/mixedmode-managedcaller.exe tools/tests/mixedmode-dllimport.dll $(TESTS_OUTDIR)/tests-x86_64/vstests
	$(WINE) $(BUILDDIR)/fixupclr.exe x86_64 $(TESTS_OUTDIR)/tests-x86_64/vstests/mixedmode-managedcaller.exe
	$(INSTALL_PE_x86_64) $(BUILDDIR)/call-mixedmode-x86_64.exe $(TESTS_OUTDIR)/tests-x86_64/vstests/call-mixedmode.exe
	$(INSTALL_PE_x86_64) $(BUILDDIR)/call-method-x86_64.exe $(TESTS_OUTDIR)/tests-x86_64/vstests/call-method.exe
	mkdir -p $(TESTS_OUTDIR)/tests-x86/vstests-native
	cp tools/tests/mixedmode-managedcaller.exe vstests/Win32/Release/nativelibrary.dll $(TESTS_OUTDIR)/tests-x86/vstests-native
	cp tools/tests/mixedmode-managedcaller-nativedir.exe.config $(TESTS_OUTDIR)/tests-x86/vstests-native/mixedmode-managedcaller.exe.config
	$(WINE) $(BUILDDIR)/fixupclr.exe x86 $(TESTS_OUTDIR)/tests-x86/vstests-native/mixedmode-managedcaller.exe
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64/vstests-native
	cp tools/tests/mixedmode-managedcaller.exe vstests/x64/Release/nativelibrary.dll $(TESTS_OUTDIR)/tests-x86_64/vstests-native
	cp tools/tests/mixedmode-managedcaller-nativedir.exe.config $(TESTS_OUTDIR)/tests-x86_64/vstests-native/mixedmode-managedcaller.exe.config
	$(WINE) $(BUILDDIR)/fixupclr.exe x86_64 $(TESTS_OUTDIR)/tests-x86_64/vstests-native/mixedmode-managedcaller.exe
	mkdir -p $(TESTS_OUTDIR)/tests-x86/vstests-native/vstests-mixed
	cp vstests/Win32/Release/mixedmodelibrary.dll $(TESTS_OUTDIR)/tests-x86/vstests-native/vstests-mixed
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64/vstests-native/vstests-mixed
	cp vstests/x64/Release/mixedmodelibrary.dll $(TESTS_OUTDIR)/tests-x86_64/vstests-native/vstests-mixed
	cp build/winemonotest-x86.dll $(TESTS_OUTDIR)/tests-x86/winemonotest.dll
	cp build/winemonotest-x86_64.dll $(TESTS_OUTDIR)/tests-x86_64/winemonotest.dll
	cp build/vtblgap-lib-x86.dll $(TESTS_OUTDIR)/tests-x86/vtblgap-lib.dll
	cp build/vtblgap-lib-x86_64.dll $(TESTS_OUTDIR)/tests-x86_64/vtblgap-lib.dll
	mkdir -p $(TESTS_OUTDIR)/tests-x86/searchgacbeforepath
	cp tools/tests/System.Windows.Forms.dll $(TESTS_OUTDIR)/tests-x86/webbrowsertest.exe $(TESTS_OUTDIR)/tests-x86/searchgacbeforepath/
	mkdir -p $(TESTS_OUTDIR)/tests-x86_64/searchgacbeforepath
	cp tools/tests/System.Windows.Forms.dll $(TESTS_OUTDIR)/tests-x86_64/webbrowsertest.exe $(TESTS_OUTDIR)/tests-x86_64/searchgacbeforepath/
.PHONY: tools-tests-install

tests: tools-tests-install

clean-tools-tests:
	rm -f $(SRCDIR)/tools/tests/*.dll $(SRCDIR)/tools/tests/*.exe
.PHONY: clean-tools-tests
clean: clean-tools-tests

define MINGW_TEMPLATE +=

$$(BUILDDIR)/call-mixedmode-$(1).exe: $$(SRCDIR)/tools/tests/call-mixedmode.c $$(MINGW_DEPS)
	$$(LLVM_MINGW_ENV) $$(MINGW_$(1))-gcc $$(filter %.lib,$$^) $$< -o $$@

tools-tests-all: $$(BUILDDIR)/call-mixedmode-$(1).exe $$(BUILDDIR)/call-method-$(1).exe

clean-call-mixedmode-$(1):
	rm -f $$(BUILDDIR)/call-mixedmode-$(1).exe
.PHONY: clean-call-mixedmode-$(1)
clean-build: clean-call-mixedmode-$(1)

$$(BUILDDIR)/call-method-$(1).exe: $$(SRCDIR)/tools/tests/call-method.c $$(MINGW_DEPS)
	$$(MINGW_ENV) $$(MINGW_$(1))-gcc -mconsole -municode $$(filter %.lib,$$^) $$< -o $$@

tools-tests-all: $$(BUILDDIR)/call-method-$(1).exe $$(BUILDDIR)/call-method-$(1).exe

clean-call-method-$(1):
	rm -f $$(BUILDDIR)/call-method-$(1).exe
.PHONY: clean-call-method-$(1)
clean-build: clean-call-method-$(1)

$$(BUILDDIR)/winemonotest-$(1).dll: $$(SRCDIR)/tools/tests/winemonotest.c $$(MINGW_DEPS)
	$$(LLVM_MINGW_ENV) $$(MINGW_$(1))-gcc -shared -Wl,--kill-at $$(filter %.lib,$$^) -loleaut32 $$< -o $$@

tools-tests-all: $$(BUILDDIR)/winemonotest-$(1).dll

clean-winemonotest-$(1):
	rm -f $$(BUILDDIR)/winemonotest-$(1).dll
.PHONY: clean-winemonotest-$(1)
clean-build: clean-winemonotest-$(1)

$$(BUILDDIR)/vtblgap-lib-$(1).dll: $$(SRCDIR)/tools/tests/vtblgap-lib.cpp $$(MINGW_DEPS)
	$$(LLVM_MINGW_ENV) $$(MINGW_$(1))-g++ -shared -luuid -lole32 $$< -static-libgcc -static-libstdc++ -o $$@

tools-tests-all: $$(BUILDDIR)/vtblgap-lib-$(1).dll

clean-vtblgap-lib-$(1):
	rm -f $$(BUILDDIR)/vtblgap-lib-$(1).dll
.PHONY: clean-vtblgap-lib-$(1)
clean-build: clean-vtblgap-lib-$(1)

endef

$(BUILDDIR)/call-mixedmode-x86.exe: $(SRCDIR)/vstests/Win32/Release/mixedmodelibrary.lib

$(BUILDDIR)/call-mixedmode-x86_64.exe: $(SRCDIR)/vstests/x64/Release/mixedmodelibrary.lib

tools-tests-csharp: $(BUILDDIR)/mono-unix/.installed $(BUILDDIR)/fixupclr.exe
	mkdir -p $(TESTS_OUTDIR)/csharp
	cp $(BUILDDIR)/mono-unix-install/lib/mono/4.5/csharp.exe $(TESTS_OUTDIR)/csharp
	cp $(TESTS_OUTDIR)/csharp/csharp.exe $(TESTS_OUTDIR)/csharp/csharp32.exe
	$(WINE) $(BUILDDIR)/fixupclr.exe x86 $(TESTS_OUTDIR)/csharp/csharp32.exe
	$(WINE) $(BUILDDIR)/fixupclr.exe x86_64 $(TESTS_OUTDIR)/csharp/csharp.exe

.PHONY: tools-tests-csharp

tests: tools-tests-csharp

