WPF_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/wpf)

define MINGW_TEMPLATE +=

# wpfgfx
$$(BUILDDIR)/wpfgfx-$(1)/.built: $$(WPF_SRCS) $$(MINGW_DEPS)
	mkdir -p $$(@D)
	+$$(MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" $(MAKE) -C $$(@D) -f $$(SRCDIR_ABS)/wpf/wpfgfx/Makefile ARCH=$(1) SRCDIR="$$(SRCDIR_ABS)/wpf/wpfgfx" "MINGW=$$(MINGW_$(1))"
	touch "$$@"
ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
ifneq (1,$(ENABLE_DOTNET_CORE_WPFGFX))
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/wpfgfx-$(1)/.built
endif
endif

$$(BUILDDIR)/wpfgfx-netcore-$(1)/.built: $$(WPF_SRCS) $$(MINGW_DEPS)
	mkdir -p $$(@D)
	+$$(LLVM_MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" $(MAKE) OBJDIR=$$(BUILDDIR_ABS)/wpfgfx-netcore-$(1) -C $$(SRCDIR_ABS)/wpf/src/Microsoft.DotNet.Wpf/src/WpfGfx "MINGW=$$(MINGW_$(1))" ARCH=$(1)
	touch "$$@"
ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
ifeq (1,$(ENABLE_DOTNET_CORE_WPFGFX))
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/wpfgfx-netcore-$(1)/.built
endif
endif

ifeq (1,$(ENABLE_DOTNET_CORE_WPFGFX))
wpfgfx-$(1).dll: $$(BUILDDIR)/wpfgfx-netcore-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib/$(1)"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/wpfgfx-netcore-$(1)/wpfgfx_cor3.dll" "$$(IMAGEDIR)/lib/$(1)/wpfgfx_cor3.dll"
else
wpfgfx-$(1).dll: $$(BUILDDIR)/wpfgfx-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib/$(1)"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/wpfgfx-$(1)/wpfgfx_cor3.dll" "$$(IMAGEDIR)/lib/$(1)/wpfgfx_cor3.dll"
endif
.PHONY: wpfgfx-$(1).dll

wpfgfx_cor3.dll wpfgfx.dll: wpfgfx-$(1).dll
.PHONY: wpfgfx_cor3.dll wpfgfx.dll

ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
imagedir-targets: wpfgfx-$(1).dll
endif

clean-build-wpfgfx-$(1):
	rm -rf $$(BUILDDIR)/wpfgfx-$(1)
.PHONY: clean-build-wpfgfx-$(1)
clean-build: clean-build-wpfgfx-$(1)

clean-build-wpfgfx-netcore-$(1):
	rm -rf $$(BUILDDIR)/wpfgfx-netcore-$(1)
.PHONY: clean-build-wpfgfx-netcore-$(1)
clean-build: clean-build-wpfgfx-netcore-$(1)

# PresentationNative
$$(BUILDDIR)/PresentationNative-$(1)/.built: $$(WPF_SRCS) $$(MINGW_DEPS)
	mkdir -p $$(@D)
	+$$(MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" $(MAKE) -C $$(@D) -f $$(SRCDIR_ABS)/wpf/PresentationNative/Makefile ARCH=$(1) SRCDIR="$$(SRCDIR_ABS)/wpf/PresentationNative" "MINGW=$$(MINGW_$(1))"
	touch "$$@"
ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/PresentationNative-$(1)/.built
endif

PresentationNative-$(1).dll: $$(BUILDDIR)/PresentationNative-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib/$(1)"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/PresentationNative-$(1)/PresentationNative_cor3.dll" "$$(IMAGEDIR)/lib/$(1)/PresentationNative_cor3.dll"
.PHONY: PresentationNative-$(1).dll

PresentationNative_cor3.dll PresentationNative.dll: PresentationNative-$(1).dll
.PHONY: PresentationNative_cor3.dll PresentationNative.dll

ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
imagedir-targets: PresentationNative-$(1).dll
endif

clean-build-PresentationNative-$(1):
	rm -rf $$(BUILDDIR)/PresentationNative-$(1)
.PHONY: clean-build-PresentationNative-$(1)
clean-build: clean-build-PresentationNative-$(1)

# wmwpfdwhelper - unmanaged helper for DirectWriteForwarder
$$(BUILDDIR)/wmwpfdwhelper-$(1)/.built: $$(WPF_SRCS) $$(MINGW_DEPS)
	mkdir -p $$(@D)
	+$$(MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" $(MAKE) -C $$(@D) -f $$(SRCDIR_ABS)/wpf/wmwpfdwhelper/Makefile ARCH=$(1) SRCDIR="$$(SRCDIR_ABS)/wpf/wmwpfdwhelper" "MINGW=$$(MINGW_$(1))"
	touch "$$@"
ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/wmwpfdwhelper-$(1)/.built
endif

wmwpfdwhelper-$(1).dll: $$(BUILDDIR)/wmwpfdwhelper-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib/$(1)"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/wmwpfdwhelper-$(1)/wmwpfdwhelper.dll" "$$(IMAGEDIR)/lib/$(1)/wmwpfdwhelper.dll"
.PHONY: wmwpfdwhelper-$(1).dll

wmwpfdwhelper.dll: wmwpfdwhelper-$(1).dll
.PHONY: wmwpfdwhelper.dll

ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
imagedir-targets: wmwpfdwhelper-$(1).dll
endif

clean-build-wmwpfdwhelper-$(1):
	rm -rf $$(BUILDDIR)/wmwpfdwhelper-$(1)
.PHONY: clean-build-wmwpfdwhelper-$(1)
clean-build: clean-build-wmwpfdwhelper-$(1)

endef

# dotnet core WPF
$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/winforms/src/Accessibility/src/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS) ACCESSIBILITY_DLL=$(SRCDIR_ABS)/winforms/src/Accessibility/src/Accessibility.dll
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Input.Manipulations/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/winforms/src/Accessibility/src/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS) ACCESSIBILITY_DLL=$(SRCDIR_ABS)/winforms/src/Accessibility/src/Accessibility.dll
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationClient/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/winforms/src/Accessibility/src/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built $(BUILDDIR)/resx2srid.exe 
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS) ACCESSIBILITY_DLL=$(SRCDIR_ABS)/winforms/src/Accessibility/src/Accessibility.dll
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Input.Manipulations/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/winforms/src/Accessibility/src/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS) ACCESSIBILITY_DLL=$(SRCDIR_ABS)/winforms/src/Accessibility/src/Accessibility.dll
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Aero/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Aero2/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Classic/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Printing/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/.built
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsFormsIntegration/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/winforms/src/System.Windows.Forms/src/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS) WINFORMS_DLL=$(SRCDIR_ABS)/winforms/src/System.Windows.Forms/src/System.Windows.Forms.dll
	touch $@

$(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Controls.Ribbon/.built: $(BUILDDIR)/mono-unix/.installed $(WPF_SRCS) $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Classic/.built $(BUILDDIR)/resx2srid.exe
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_PREFIX=$(BUILDDIR_ABS)/mono-unix-install RESX2SRID=$(BUILDDIR_ABS)/resx2srid.exe WINE_MONO_SRCDIR=$(SRCDIR_ABS)
	touch $@

ifeq (1,$(ENABLE_DOTNET_CORE_WPF))
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built

System.Xaml.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Xaml/System.Xaml.dll -root $(IMAGEDIR)/lib
.PHONY: System.Xaml.dll
imagedir-targets: System.Xaml.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built

WindowsBase.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsBase/WindowsBase.dll -root $(IMAGEDIR)/lib
.PHONY: WindowsBase.dll
imagedir-targets: WindowsBase.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Input.Manipulations/.built

System.Windows.Input.Manipulations.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Input.Manipulations/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Input.Manipulations/System.Windows.Input.Manipulations.dll -root $(IMAGEDIR)/lib
.PHONY: System.Windows.Input.Manipulations.dll
imagedir-targets: System.Windows.Input.Manipulations.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built

UIAutomationTypes.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationTypes/UIAutomationTypes.dll -root $(IMAGEDIR)/lib
.PHONY: UIAutomationTypes.dll
imagedir-targets: UIAutomationTypes.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built

UIAutomationProvider.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationProvider/UIAutomationProvider.dll -root $(IMAGEDIR)/lib
.PHONY: UIAutomationProvider.dll
imagedir-targets: UIAutomationProvider.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationClient/.built

UIAutomationClient.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationClient/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/UIAutomation/UIAutomationClient/UIAutomationClient.dll -root $(IMAGEDIR)/lib
.PHONY: UIAutomationClient.dll
imagedir-targets: UIAutomationClient.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built

PresentationCore.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationCore/PresentationCore.dll -root $(IMAGEDIR)/lib
.PHONY: PresentationCore.dll
imagedir-targets: PresentationCore.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/.built

ReachFramework.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/ReachFramework/ReachFramework.dll -root $(IMAGEDIR)/lib
.PHONY: ReachFramework.dll
imagedir-targets: ReachFramework.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built

PresentationFramework.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/PresentationFramework.dll -root $(IMAGEDIR)/lib
.PHONY: PresentationFramework.dll
imagedir-targets: PresentationFramework.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/.built

PresentationUI.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/PresentationUI/PresentationUI.dll -root $(IMAGEDIR)/lib
.PHONY: PresentationUI.dll
imagedir-targets: PresentationUI.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Aero/.built

PresentationFramework.Aero.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Aero/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Aero/PresentationFramework.Aero.dll -root $(IMAGEDIR)/lib
.PHONY: PresentationFramework.Aero.dll
imagedir-targets: PresentationFramework.Aero.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Aero2/.built

PresentationFramework.Aero2.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Aero2/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Aero2/PresentationFramework.Aero2.dll -root $(IMAGEDIR)/lib
.PHONY: PresentationFramework.Aero2.dll
imagedir-targets: PresentationFramework.Aero2.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Classic/.built

PresentationFramework.Classic.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Classic/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/Themes/PresentationFramework.Classic/PresentationFramework.Classic.dll -root $(IMAGEDIR)/lib
.PHONY: PresentationFramework.Classic.dll
imagedir-targets: PresentationFramework.Classic.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Printing/.built

System.Printing.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Printing/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Printing/System.Printing.dll -root $(IMAGEDIR)/lib
.PHONY: System.Printing.dll
imagedir-targets: System.Printing.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsFormsIntegration/.built

WindowsFormsIntegration.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsFormsIntegration/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/WindowsFormsIntegration/WindowsFormsIntegration.dll -root $(IMAGEDIR)/lib
.PHONY: WindowsFormsIntegration.dll
imagedir-targets: WindowsFormsIntegration.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Controls.Ribbon/.built

System.Windows.Controls.Ribbon.dll: $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Controls.Ribbon/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/wpf/src/Microsoft.DotNet.Wpf/src/System.Windows.Controls.Ribbon/System.Windows.Controls.Ribbon.dll -root $(IMAGEDIR)/lib
.PHONY: System.Windows.Controls.Ribbon.dll
imagedir-targets: System.Windows.Controls.Ribbon.dll
endif

