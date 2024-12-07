# targets for building the support msi

# machine.config
$(foreach arch,Framework Framework64,$(foreach version,v1.1.4322 v2.0.50727,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/$(version)/CONFIG/machine.config)): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-unix-install/etc/mono/2.0/machine.config $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(foreach version,v1.1.4322 v2.0.50727,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/$(version)/CONFIG/machine.config))

$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/CONFIG/machine.config): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-unix-install/etc/mono/4.0/machine.config $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/CONFIG/machine.config)

# security.config
$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/CONFIG/security.config): $(SRCDIR)/security.config
	mkdir -p $(@D)
	cp $(SRCDIR)/security.config $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/CONFIG/security.config)

# mscorlib.dll
$(foreach arch,Framework Framework64,$(foreach version,v1.1.4322 v2.0.50727,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/$(version)/mscorlib.dll)): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-unix-install/lib/mono/2.0-api/mscorlib.dll $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(foreach version,v1.1.4322 v2.0.50727,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/$(version)/mscorlib.dll))

$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/mscorlib.dll): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-unix-install/lib/mono/4.0/mscorlib.dll $@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/mscorlib.dll)

# csc.exe
$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/csc.exe): $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/tools/csc-wrapper/csc-wrapper.cs
	mkdir -p $(@D)
	$(MONO_ENV) mcs $(SRCDIR)/tools/csc-wrapper/csc-wrapper.cs /d:VERSION20 -out:$@ -r:WineMono.Posix
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/csc.exe)

$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/csc.exe): $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/tools/csc-wrapper/csc-wrapper.cs
	mkdir -p $(@D)
	$(MONO_ENV) mcs $(SRCDIR)/tools/csc-wrapper/csc-wrapper.cs /d:VERSION40 -out:$@ -r:WineMono.Posix
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/csc.exe)

# installutil.exe
$(foreach version,v2.0.50727 v4.0.30319,$(BUILDDIR)/image-support/Microsoft.NET/Framework/$(version)/installutil.exe): $(BUILDDIR)/mono-unix/.installed $(BUILDDIR)/fixupclr.exe
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-win32-install/lib/mono/4.5/installutil.exe $@
	$(WINE) $(BUILDDIR)/fixupclr.exe x86 $@
IMAGE_SUPPORT_FILES += $(foreach version,v2.0.50727 v4.0.30319,$(BUILDDIR)/image-support/Microsoft.NET/Framework/$(version)/installutil.exe)

$(foreach version,v2.0.50727 v4.0.30319,$(BUILDDIR)/image-support/Microsoft.NET/Framework64/$(version)/installutil.exe): $(BUILDDIR)/mono-unix/.installed
	mkdir -p $(@D)
	cp $(BUILDDIR)/mono-win32-install/lib/mono/4.5/installutil.exe $@
IMAGE_SUPPORT_FILES += $(foreach version,v2.0.50727 v4.0.30319,$(BUILDDIR)/image-support/Microsoft.NET/Framework64/$(version)/installutil.exe)

# msbuild.exe
$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/msbuild.exe): $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/tools/msbuild/msbuild.cs
	mkdir -p $(@D)
	$(MONO_ENV) mcs $(SRCDIR)/tools/msbuild/msbuild.cs /d:VERSION20 -out:$@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v2.0.50727/msbuild.exe)

$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v3.5/msbuild.exe): $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/tools/msbuild/msbuild.cs
	mkdir -p $(@D)
	$(MONO_ENV) mcs $(SRCDIR)/tools/msbuild/msbuild.cs /d:VERSION35 -out:$@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v3.5/msbuild.exe)

$(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/msbuild.exe): $(BUILDDIR)/mono-unix/.installed $(SRCDIR)/tools/msbuild/msbuild.cs
	mkdir -p $(@D)
	$(MONO_ENV) mcs $(SRCDIR)/tools/msbuild/msbuild.cs /d:VERSION40 -out:$@
IMAGE_SUPPORT_FILES += $(foreach arch,Framework Framework64,$(BUILDDIR)/image-support/Microsoft.NET/$(arch)/v4.0.30319/msbuild.exe)

$(BUILDDIR)/.supportemptydirs: $(SRCDIR)/support.make
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/Framework/v3.0/wpf
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/Framework/v3.0/"windows communication foundation"
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/Framework64/v3.0/wpf
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/Framework64/v3.0/"windows communication foundation"
	mkdir -p $(BUILDDIR)/image-support/Microsoft.NET/"DirectX for Managed Code"
	touch $@
IMAGE_SUPPORT_FILES += $(BUILDDIR)/.supportemptydirs

clean-image-support:
	rm -rf $(BUILDDIR)/image-support $(BUILDDIR)/.supportemptydirs
.PHONY: clean-image-support
clean-build: clean-image-support

$(BUILDDIR)/.supportmsitables-built: $(IMAGE_SUPPORT_FILES) $(SRCDIR)/msi-tables/support/*.idt $(SRCDIR)/tools/build-msi-tables.sh $(BUILDDIR)/genfilehashes.exe $(SRCDIR)/support.make
	$(MONO_ENV) WHICHMSI=support MSI_VERSION=$(MSI_VERSION) CABFILENAME=$(BUILDDIR_ABS)/winemono-support.cab TABLEDIR=$(BUILDDIR_ABS)/msi-tables/support TABLESRCDIR=$(SRCDIR_ABS)/msi-tables/support IMAGEDIR=$(BUILDDIR_ABS)/image-support ROOTDIR=WindowsFolder CABINET=winemono-support.cab GENFILEHASHES=$(BUILDDIR_ABS)/genfilehashes.exe WINE=$(WINE) sh $(SRCDIR)/tools/build-msi-tables.sh
	touch $@

clean-msi-tables:
	rm -rf $(BUILDDIR)/msi-tables $(BUILDDIR)/.supportmsitables-built $(BUILDDIR)/winemono-support.cab
.PHONY: clean-msi-tables
clean-build: clean-msi-tables

$(BUILDDIR)/winemono-support.msi: $(BUILDDIR)/.supportmsitables-built
	rm -f "$@"
	$(WINE) winemsibuilder -i '$(shell $(WINE) winepath -w $@)' $(BUILDDIR)/msi-tables/support/*.idt
IMAGEDIR_BUILD_TARGETS += $(BUILDDIR)/winemono-support.msi

clean-support-msi:
	rm -rf $(BUILDDIR)/winemono-support.msi
.PHONY: clean-support-msi
clean-build: clean-support-msi

winemono-support.msi winemono-support.cab: $(BUILDDIR)/winemono-support.msi
	mkdir -p $(IMAGEDIR)/support/
	cp $(BUILDDIR)/winemono-support.cab $(BUILDDIR)/winemono-support.msi $(IMAGEDIR)/support/
.PHONY: winemono-support.msi winemono-support.cab
imagedir-targets: winemono-support.msi

