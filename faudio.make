FAUDIO_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/FAudio)

define MINGW_TEMPLATE +=

# FAudio
$$(BUILDDIR)/FAudio-$(1)/Makefile: $$(SRCDIR)/FNA/lib/FAudio/CMakeLists.txt $$(SRCDIR)/faudio.make $$(MINGW_DEPS)
	$(RM_F) $$(@D)/CMakeCache.txt
	mkdir -p $$(@D)
	cd $$(@D); CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" $$(MINGW_ENV) cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DPLATFORM_WIN32=ON $$(SRCDIR_ABS)/FNA/lib/FAudio

$$(BUILDDIR)/FAudio-$(1)/.built: $$(BUILDDIR)/FAudio-$(1)/Makefile $$(FAUDIO_SRCS) $$(MINGW_DEPS)
	+$$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/FAudio-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS_$(1) += $$(BUILDDIR)/FAudio-$(1)/.built

FAudio-$(1).dll: $$(BUILDDIR)/FAudio-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib/$(2)"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/FAudio-$(1)/FAudio.dll" "$$(IMAGEDIR)/lib/$(2)/FAudio.dll"
.PHONY: FAudio-$(1).dll
imagedir-targets-$(1): FAudio-$(1).dll

ifeq ($$(NATIVE_$(1)),1)
FAudio.dll: FAudio-$(1).dll
.PHONY: FAudio.dll
endif

clean-build-FAudio-$(1):
	rm -rf $$(BUILDDIR)/FAudio-$(1)
.PHONY: clean-build-FAudio-$(1)
clean-build: clean-build-FAudio-$(1)

endef

