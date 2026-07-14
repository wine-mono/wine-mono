MONODX_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/monoDX)

define MINGW_TEMPLATE +=
# monodx
$$(BUILDDIR)/monodx-$(1)/.built: $$(MONODX_SRCS) $$(MINGW_DEPS)
	mkdir -p $$(@D)
	+$$(MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" $(MAKE) -C $$(@D) -f $$(SRCDIR_ABS)/monoDX/monodx/Makefile ARCH=$(1) SRCDIR="$$(SRCDIR_ABS)/monoDX/monodx" "MINGW=$$(MINGW_$(1))"
	touch "$$@"
ifeq (1,$(ENABLE_MONODX))
IMAGEDIR_BUILD_TARGETS_$(1) += $$(BUILDDIR)/monodx-$(1)/.built
endif

monodx-$(1).dll: $$(BUILDDIR)/monodx-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib/$(2)"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/monodx-$(1)/monodx.dll" "$$(IMAGEDIR)/lib/$(2)/monodx.dll"
.PHONY: monodx-$(1).dll

ifeq ($$(NATIVE_$(1)),1)
monodx.dll: monodx-$(1).dll
.PHONY: monodx.dll
endif

ifeq (1,$(ENABLE_MONODX))
imagedir-targets-$(1): monodx-$(1).dll
endif

clean-build-monodx-$(1):
	rm -rf $$(BUILDDIR)/monodx-$(1)
.PHONY: clean-build-monodx-$(1)
clean-build: clean-build-monodx-$(1)
endef

# monodx
$(SRCDIR)/monoDX/FixupConstructors/.built: $(BUILDDIR)/mono-unix/.installed $(MONODX_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(@D) MONO_CECIL_DLL=$(BUILDDIR_ABS)/mono-unix-install/lib/mono/gac/Mono.Cecil/0.11.1.0__0738eb9f132ed756/Mono.Cecil.dll
	touch $@

$(SRCDIR)/monoDX/Microsoft.DirectX/.built: $(BUILDDIR)/mono-unix/.installed $(MONODX_SRCS) $(SRCDIR)/monoDX/FixupConstructors/.built
	+$(MONO_ENV) $(MAKE) -C $(@D)
	touch $@

$(SRCDIR)/monoDX/Microsoft.DirectX.Direct3D/.built: $(BUILDDIR)/mono-unix/.installed $(MONODX_SRCS) $(SRCDIR)/monoDX/FixupConstructors/.built $(SRCDIR)/monoDX/Microsoft.DirectX/.built
	+$(MONO_ENV) $(MAKE) -C $(@D)
	touch $@

$(SRCDIR)/monoDX/Microsoft.DirectX.Direct3DX/.built: $(BUILDDIR)/mono-unix/.installed $(MONODX_SRCS) $(SRCDIR)/monoDX/Microsoft.DirectX.Direct3D/.built
	+$(MONO_ENV) $(MAKE) -C $(@D)
	touch $@

$(SRCDIR)/monoDX/Microsoft.DirectX.DirectInput/.built: $(BUILDDIR)/mono-unix/.installed $(MONODX_SRCS) $(SRCDIR)/monoDX/FixupConstructors/.built $(SRCDIR)/monoDX/Microsoft.DirectX/.built
	+$(MONO_ENV) $(MAKE) -C $(@D)
	touch $@

$(SRCDIR)/monoDX/Microsoft.DirectX.DirectPlay/.built: $(BUILDDIR)/mono-unix/.installed $(MONODX_SRCS) $(SRCDIR)/monoDX/Microsoft.DirectX/.built
	+$(MONO_ENV) $(MAKE) -C $(@D)
	touch $@

$(SRCDIR)/monoDX/Microsoft.DirectX.DirectSound/.built: $(BUILDDIR)/mono-unix/.installed $(MONODX_SRCS) $(SRCDIR)/monoDX/Microsoft.DirectX/.built $(SRCDIR)/monoDX/FixupConstructors/.built
	+$(MONO_ENV) $(MAKE) -C $(@D)
	touch $@

ifeq (1,$(ENABLE_MONODX))
IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/monoDX/Microsoft.DirectX/.built
Microsoft.DirectX.dll: $(SRCDIR)/monoDX/Microsoft.DirectX/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/monoDX/Microsoft.DirectX/Microsoft.DirectX.dll -root $(IMAGEDIR)/lib
.PHONY: Microsoft.DirectX.dll
imagedir-targets: Microsoft.DirectX.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/monoDX/Microsoft.DirectX.Direct3D/.built
Microsoft.DirectX.Direct3D.dll: $(SRCDIR)/monoDX/Microsoft.DirectX.Direct3D/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/monoDX/Microsoft.DirectX.Direct3D/Microsoft.DirectX.Direct3D.dll -root $(IMAGEDIR)/lib
.PHONY: Microsoft.DirectX.Direct3D.dll
imagedir-targets: Microsoft.DirectX.Direct3D.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/monoDX/Microsoft.DirectX.Direct3DX/.built
Microsoft.DirectX.Direct3DX.dll: $(SRCDIR)/monoDX/Microsoft.DirectX.Direct3DX/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/monoDX/Microsoft.DirectX.Direct3DX/Microsoft.DirectX.Direct3DX.dll -root $(IMAGEDIR)/lib
.PHONY: Microsoft.DirectX.Direct3DX.dll
imagedir-targets: Microsoft.DirectX.Direct3DX.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/monoDX/Microsoft.DirectX.DirectInput/.built
Microsoft.DirectX.DirectInput.dll: $(SRCDIR)/monoDX/Microsoft.DirectX.DirectInput/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/monoDX/Microsoft.DirectX.DirectInput/Microsoft.DirectX.DirectInput.dll -root $(IMAGEDIR)/lib
.PHONY: Microsoft.DirectX.DirectInput.dll
imagedir-targets: Microsoft.DirectX.DirectInput.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/monoDX/Microsoft.DirectX.DirectPlay/.built
Microsoft.DirectX.DirectPlay.dll: $(SRCDIR)/monoDX/Microsoft.DirectX.DirectPlay/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/monoDX/Microsoft.DirectX.DirectPlay/Microsoft.DirectX.DirectPlay.dll -root $(IMAGEDIR)/lib
.PHONY: Microsoft.DirectX.DirectPlay.dll
imagedir-targets: Microsoft.DirectX.DirectPlay.dll

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/monoDX/Microsoft.DirectX.DirectSound/.built
Microsoft.DirectX.DirectSound.dll: $(SRCDIR)/monoDX/Microsoft.DirectX.DirectSound/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/monoDX/Microsoft.DirectX.DirectSound/Microsoft.DirectX.DirectSound.dll -root $(IMAGEDIR)/lib
.PHONY: Microsoft.DirectX.DirectSound.dll
imagedir-targets: Microsoft.DirectX.DirectSound.dll
endif
