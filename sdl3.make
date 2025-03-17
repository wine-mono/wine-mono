
SDL3_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/SDL3)

define MINGW_TEMPLATE +=

$$(BUILDDIR)/SDL3-$(1)/Makefile: $$(SRCDIR)/SDL3/CMakeLists.txt $$(SRCDIR)/sdl3.make $$(MINGW_DEPS)
	$(RM_F) $$(@D)/CMakeCache.txt
	mkdir -p $$(@D)
	cd $$(@D); CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" $$(MINGW_ENV) cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DPLATFORM_WIN32=ON $$(SRCDIR_ABS)/SDL3

$$(BUILDDIR)/SDL3-$(1)/.built: $$(BUILDDIR)/SDL3-$(1)/Makefile $$(SDL3_SRCS) $$(MINGW_DEPS)
	+WINEPREFIX=/dev/null $$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/SDL3-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/SDL3-$(1)/.built

SDL3-$(1).dll: $$(BUILDDIR)/SDL3-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/SDL3-$(1)/SDL3.dll" "$$(IMAGEDIR)/lib/$(1)/SDL3.dll"
.PHONY: SDL3-$(1).dll
imagedir-targets: SDL3-$(1).dll

SDL3.dll: SDL3-$(1).dll
.PHONY: SDL3.dll

clean-build-SDL3-$(1):
	rm -rf $$(BUILDDIR)/SDL3-$(1)
.PHONY: clean-build-SDL3-$(1)
clean-build: clean-build-SDL3-$(1)

endef

