MONO_BASIC_COMPAT_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/mono-basic-compat)

$(SRCDIR)/mono-basic-compat/.built: $(BUILDDIR)/mono-unix/.installed $(MONO_BASIC_COMPAT_SRCS)
	+$(MONO_ENV) $(MAKE) -C $(@D)
	touch $@

IMAGEDIR_BUILD_TARGETS += $(SRCDIR)/mono-basic-compat/.built

Microsoft.VisualBasic.Compatibility.dll: $(SRCDIR)/mono-basic-compat/.built
	$(MONO_ENV) gacutil -i $(SRCDIR)/mono-basic-compat/Microsoft.VisualBasic.Compatibility.dll -root $(IMAGEDIR)/lib
.PHONY: Microsoft.VisualBasic.Compatibility.dll
imagedir-targets: Microsoft.VisualBasic.Compatibility.dll

