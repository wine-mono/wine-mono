FNA3D_SRCS=$(shell $(SRCDIR)/tools/git-updated-files $(SRCDIR)/FNA/lib/FNA3D)

define MINGW_TEMPLATE +=

# FNA3D
ifeq (1,$$(ENABLE_SDL3))
$$(BUILDDIR)/FNA3D-$(1)/Makefile: $$(SRCDIR)/FNA/lib/FNA3D/CMakeLists.txt $$(SRCDIR)/fna3d.make $$(BUILDDIR)/SDL3-$(1)/.built $$(MINGW_DEPS)
	$(RM_F) $$(@D)/CMakeCache.txt
	mkdir -p $$(@D)
	cd $$(@D); $$(MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DSDL3_INCLUDE_DIRS="$$(BUILDDIR_ABS)/SDL3-$(1)/include-revision;$$(SRCDIR_ABS)/SDL3/include" -DSDL3_LIBRARIES="$$(BUILDDIR_ABS)/SDL3-$(1)/libSDL3.dll.a" -DBUILD_SDL3:BOOL=ON $$(SRCDIR_ABS)/FNA/lib/FNA3D
else
$$(BUILDDIR)/FNA3D-$(1)/Makefile: $$(SRCDIR)/FNA/lib/FNA3D/CMakeLists.txt $$(SRCDIR)/fna3d.make $$(BUILDDIR)/SDL2-$(1)/.built $$(MINGW_DEPS)
	$(RM_F) $$(@D)/CMakeCache.txt
	mkdir -p $$(@D)
	cd $$(@D); $$(MINGW_ENV) CFLAGS="$$(PDB_CFLAGS_$(1))" CXXFLAGS="$$(PDB_CFLAGS_$(1))" LDFLAGS="$$(PDB_LDFLAGS_$(1))" cmake -DCMAKE_TOOLCHAIN_FILE="$$(SRCDIR_ABS)/toolchain-$(1).cmake" -DCMAKE_C_COMPILER=$$(MINGW_$(1))-gcc -DCMAKE_CXX_COMPILER=$$(MINGW_$(1))-g++ -DSDL2_INCLUDE_DIRS="$$(BUILDDIR_ABS)/SDL2-$(1)/include;$$(SRCDIR_ABS)/SDL2/include" -DSDL2_LIBRARIES="$$(BUILDDIR_ABS)/SDL2-$(1)/build/.libs/libSDL2.dll.a" $$(SRCDIR_ABS)/FNA/lib/FNA3D
endif

$$(BUILDDIR)/FNA3D-$(1)/.built: $$(BUILDDIR)/FNA3D-$(1)/Makefile $$(FNA3D_SRCS) $$(MINGW_DEPS)
	+$$(MINGW_ENV) $$(MAKE) -C $$(BUILDDIR)/FNA3D-$(1)
	touch "$$@"
IMAGEDIR_BUILD_TARGETS += $$(BUILDDIR)/FNA3D-$(1)/.built

FNA3D-$(1).dll: $$(BUILDDIR)/FNA3D-$(1)/.built
	mkdir -p "$$(IMAGEDIR)/lib/$(1)"
	$$(INSTALL_PE_$(1)) "$$(BUILDDIR)/FNA3D-$(1)/FNA3D.dll" "$$(IMAGEDIR)/lib/$(1)/FNA3D.dll"
.PHONY: FNA3D-$(1).dll
imagedir-targets: FNA3D-$(1).dll

FNA3D.dll: FNA3D-$(1).dll
.PHONY: FNA3D.dll

clean-build-FNA3D-$(1):
	rm -rf $$(BUILDDIR)/FNA3D-$(1)
.PHONY: clean-build-FNA3D-$(1)
clean-build: clean-build-FNA3D-$(1)

endef

