Wine Mono is a package containing Framework Mono and other projects, intended as a replacement for the .NET Framework (4.8 and earlier) in Wine. It works in conjunction with Wine's builtin mscoree.dll, and it is not intended to be useful for any other purpose.

# **Simplified Instructions for Linux Mint/Ubuntu**
#### (For other distros, please refer to Original instructions)

### **Dependencies**

To install the required dependencies, open the terminal in the Wine Mono folder and run the following commands:

> chmod +x install-dependencies.sh

**Then:**

> ./install-dependencies.sh

#### Python

You will also need Python. To check if it is already installed, run:

> python --version

If you do not have Python installed, you can install it by running:

> sudo apt install python -y

### **Install Wine Mono**
To build and install Wine Mono, simply run the following commands in the terminal:

>chmod +x wine-mono-installer-mint.sh

**Then:**

> ./wine-mono-installer-mint.sh

# Original instructions (for Power Users)

### SOURCE CODE

To obtain the source code, clone it from gitlab:

$ git clone --recursive https://gitlab.winehq.org/mono/wine-mono.git

To get to the source code for a specific release, check out the appropriate tag, and update the submodules:

$ git checkout wine-mono-9.0.0 $ git submodule update --init --recursive

Source tarballs and binary packages are available at https://dl.winehq.org/wine/wine-mono/

### DEPENDENCIES

To build Wine Mono, you will need the following:

- All of the dependencies of Mono for your native (presumably Linux) system, such as autotools, CMake and a C++ compiler.
- Wine, for the winemsibuilder and cabarc commands. A 32-bit Wine is not necessary, despite the warnings when running 64-bit Wine.
- Python, to support the build system.
- libgdiplus, to support Mono's resource compiler.
- Optional: The zip or 7z command, for the tests-zip target only.

When using the Podman build container, only Podman is required on the host machine.

### BUILD

To build Wine Mono, use the msi or bin target.

$ make msi

To use a Podman container, prepend podman- to the build target.

$ make podman-msi

### INSTALL

To install Wine Mono, run the generated msi file with msiexec:

$ wine msiexec /i wine-mono-9.0.0-x86.msi

Note that if a Wine Mono with a version number >= to this file is already installed, that command will do nothing, so you may have to remove the existing version (using 'wine uninstaller') first.

If the install succeeds, it won't output anything. You can use 'wine uninstaller' to verify that the version you expect is installed.

If you are building for development, you may find it more convenient to use the 'make dev' target, which builds a runtime in image/ and configures a wine prefix to use it. You can then rebuild individual dlls using their filename with no path. See 'make help' for details.

Packagers should extract the tarball from the "make bin" target to /usr/share/wine/mono or the corresponding directory for the prefix used to configure Wine. This should create a directory named something like /usr/share/wine/mono/wine-mono-9.0.0. This conserves space compared to the msi because it doesn't need to be copied into every prefix.

### COMPOSITION

An installed Wine Mono contains the following:

- Registry keys and files in C:\windows\Microsoft.NET intended to make it look as if .NET Framework is installed, so that applications won't complain that it's missing, and the installers for .NET Framework won't install. This is part of an msi package named "Wine Mono Windows Support". (Wine Mono should always be removed before installing .NET Framework 4.8 and earlier. Wine Mono can coexist with .NET Core and .NET 5 or later.)
- A modified version of the Framework Mono runtime and class libraries, in the "Wine Mono Runtime" msi or a shared location outside the prefix.
- Other supporting libraries that are not part of Framework Mono, in some cases replacing Framework Mono's version, also stored in the "Wine Mono Runtime" msi or a shared location.

### BUGS

Bugs should be filed in the Wine bugzilla (http://bugs.winehq.org/) with product set to "Wine" and component set to "mscoree".

### PATCHES

Patches to the top-level project should be sent as a merge request to https://gitlab.winehq.org/mono/wine-mono. There is also an official mirror on GitHub where Pull Requests can be sent, at https://github.com/wine-mono/wine-mono. This creates more work for the maintainer, so it's not preferred, but it may make sense if you're on GitHub already and only planning to send a single change.

Patches to Mono should be sent as a merge request to https://gitlab.winehq.org/mono/mono. Ideally, most MRs should be for Framework Mono, which is the main branch. If the change is specific to Wine Mono, then the MR should be for the wine-mono branch.

Changes to upstream projects that make sense only within the context of wine-mono and not for the project's general use case should be sent as a merge request to the appropriate fork in https://gitlab.winehq.org/mono, on the wine-mono branch.

FNA and related projects have been very responsive to pull requests, and it's worth sending changes upstream to https://github.com/FNA-XNA/FNA.

The winforms and wpf projects are not being updated from upstream and have diverged significantly. Since they are supporting modern .NET, which adds new features and is not binary-compatible with .NET Framework, their use case is very different from ours. Any changes should be sent directly to the appropriate fork, but feel free to also send them upstream if it makes sense.å
