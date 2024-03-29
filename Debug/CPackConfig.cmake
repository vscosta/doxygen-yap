# This file will be configured to contain variables for CPack. These variables
# should be set in the CMake list file of the project before CPack module is
# included. The list of available CPACK_xxx variables and their associated
# documentation may be obtained using
#  cpack --help-variable-list
#
# Some variables are common to all generators (e.g. CPACK_PACKAGE_NAME)
# and some are specific to a generator
# (e.g. CPACK_NSIS_EXTRA_INSTALL_COMMANDS). The generator specific variables
# usually begin with CPACK_<GENNAME>_xxxx.


set(CPACK_BUILD_SOURCE_DIRS "/home/vsc/github/doxygen;/home/vsc/github/doxygen/Debug")
set(CPACK_CMAKE_GENERATOR "Unix Makefiles")
set(CPACK_COMPONENT_UNSPECIFIED_HIDDEN "TRUE")
set(CPACK_COMPONENT_UNSPECIFIED_REQUIRED "TRUE")
set(CPACK_DEBIAN_PACKAGE_CONFLICTS "graphviz (<< 1.12)")
set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "Doxygen is the de facto standard tool for generating documentation from annotated C++ sources.
 But many other popular programming languages are supported:
 C, Objective-C, C#, PHP, Java, Python, Fortran, D (some extent), and IDL (Corba, Microsoft, and UNO/OpenOffice flavors).
 Doxygen also supports the hardware description language VHDL.
 .
 Three usages:
 .
    1. Generate documentation from annotated source files to various format:
       - On-line documentation (HTML)
       - Off-line reference manual (LaTeX, RTF, PostScript, hyperlinked PDF, compressed HTML, Unix man pages)
 .
    2. Extract the code structure from undocumented source files.
       Also generate include dependency graphs, inheritance diagrams, and collaboration diagrams.
       Useful to quickly understand code organization in large source distributions.
 .
    3. Create normal documentation (as the doxygen user manual and web-site http://doxygen.org/)
 .
 Install the doxygen-latex package to build LaTeX based documents.
 Install the libclang1 package to use the 'clang assisted parsing'.")
set(CPACK_DEBIAN_PACKAGE_HOMEPAGE "https://doxygen.org/")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Matthias Klose <doko@debian.org>")
set(CPACK_DEBIAN_PACKAGE_SECTION "devel")
set(CPACK_DEBIAN_PACKAGE_SHLIBDEPS "YES")
set(CPACK_DEBIAN_PACKAGE_SUGGESTS "doxygen-latex, doxygen-doc, doxygen-gui, graphviz, libclang1")
set(CPACK_DEFAULT_PACKAGE_DESCRIPTION_FILE "/usr/share/cmake/Templates/CPack.GenericDescription.txt")
set(CPACK_DEFAULT_PACKAGE_DESCRIPTION_SUMMARY "doxygen built using CMake")
set(CPACK_DMG_BACKGROUND_IMAGE "/home/vsc/github/doxygen/doc/doxygen_logo.eps")
set(CPACK_DMG_FORMAT "UDBZ")
set(CPACK_DMG_SLA_USE_RESOURCE_FILE_LICENSE "ON")
set(CPACK_DMG_VOLUME_NAME "doxygen")
set(CPACK_GENERATOR "RPM;TGZ;STGZ")
set(CPACK_INSTALL_CMAKE_PROJECTS "/home/vsc/github/doxygen/Debug;doxygen;ALL;/")
set(CPACK_INSTALL_PREFIX "/usr/local")
set(CPACK_MODULE_PATH "/home/vsc/github/doxygen/cmake;/home/vsc/github/doxygen/cmake/Sanitizers")
set(CPACK_NSIS_DISPLAY_NAME "doxygen 1.9.8")
set(CPACK_NSIS_INSTALLER_ICON_CODE "")
set(CPACK_NSIS_INSTALLER_MUI_ICON_CODE "")
set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")
set(CPACK_NSIS_MUI_ICON "/home/vsc/github/doxygen/addon/doxywizard/doxywizard.ico")
set(CPACK_NSIS_PACKAGE_NAME "doxygen")
set(CPACK_NSIS_UNINSTALL_NAME "Uninstall")
set(CPACK_NSIS_URL_INFO_ABOUT "https://doxygen.org/")
set(CPACK_OBJCOPY_EXECUTABLE "/usr/bin/objcopy")
set(CPACK_OBJDUMP_EXECUTABLE "/usr/bin/objdump")
set(CPACK_OUTPUT_CONFIG_FILE "/home/vsc/github/doxygen/Debug/CPackConfig.cmake")
set(CPACK_PACKAGE_CONTACT "Dimitri van Heesch")
set(CPACK_PACKAGE_DEFAULT_LOCATION "/")
set(CPACK_PACKAGE_DESCRIPTION "Doxygen is the de facto standard tool for generating documentation from annotated C++ sources.
 But many other popular programming languages are supported:
 C, Objective-C, C#, PHP, Java, Python, Fortran, D (some extent), and IDL (Corba, Microsoft, and UNO/OpenOffice flavors).
 Doxygen also supports the hardware description language VHDL.
 .
 Three usages:
 .
    1. Generate documentation from annotated source files to various format:
       - On-line documentation (HTML)
       - Off-line reference manual (LaTeX, RTF, PostScript, hyperlinked PDF, compressed HTML, Unix man pages)
 .
    2. Extract the code structure from undocumented source files.
       Also generate include dependency graphs, inheritance diagrams, and collaboration diagrams.
       Useful to quickly understand code organization in large source distributions.
 .
    3. Create normal documentation (as the doxygen user manual and web-site http://doxygen.org/)
 .
 Install the doxygen-latex package to build LaTeX based documents.
 Install the libclang1 package to use the 'clang assisted parsing'.")
set(CPACK_PACKAGE_DESCRIPTION_FILE "/usr/share/cmake/Templates/CPack.GenericDescription.txt")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Generate documentation from C, C++, Java, Python and other languages")
set(CPACK_PACKAGE_FILE_NAME "doxygen-1.9.8-rolling.x86_64")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "doxygen 1.9.8")
set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "doxygen 1.9.8")
set(CPACK_PACKAGE_NAME "doxygen")
set(CPACK_PACKAGE_RELOCATABLE "true")
set(CPACK_PACKAGE_VENDOR "Dimitri van Heesch")
set(CPACK_PACKAGE_VERSION "1.9.8")
set(CPACK_PACKAGE_VERSION_MAJOR "1")
set(CPACK_PACKAGE_VERSION_MINOR "11")
set(CPACK_PACKAGE_VERSION_PATCH "0")
set(CPACK_READELF_EXECUTABLE "/usr/bin/readelf")
set(CPACK_RESOURCE_FILE_LICENSE "/home/vsc/github/doxygen/LICENSE")
set(CPACK_RESOURCE_FILE_README "/home/vsc/github/doxygen/README.md")
set(CPACK_RESOURCE_FILE_WELCOME "/usr/share/cmake/Templates/CPack.GenericWelcome.txt")
set(CPACK_RPM_PACKAGE_ARCHITECTURE "x86_64")
set(CPACK_RPM_PACKAGE_DESCRIPTION "Doxygen is the de facto standard tool for generating documentation from annotated C++ sources.
 But many other popular programming languages are supported:
 C, Objective-C, C#, PHP, Java, Python, Fortran, D (some extent), and IDL (Corba, Microsoft, and UNO/OpenOffice flavors).
 Doxygen also supports the hardware description language VHDL.
 .
 Three usages:
 .
    1. Generate documentation from annotated source files to various format:
       - On-line documentation (HTML)
       - Off-line reference manual (LaTeX, RTF, PostScript, hyperlinked PDF, compressed HTML, Unix man pages)
 .
    2. Extract the code structure from undocumented source files.
       Also generate include dependency graphs, inheritance diagrams, and collaboration diagrams.
       Useful to quickly understand code organization in large source distributions.
 .
    3. Create normal documentation (as the doxygen user manual and web-site http://doxygen.org/)
 .
 Install the doxygen-latex package to build LaTeX based documents.
 Install the libclang1 package to use the 'clang assisted parsing'.")
set(CPACK_RPM_PACKAGE_GROUP "Development/Tools")
set(CPACK_RPM_PACKAGE_LICENSE "GPLv2")
set(CPACK_RPM_PACKAGE_REQUIRES "/sbin/chkconfig, /bin/mktemp, /bin/rm, /bin/mv, libstdc++ >= 2.96")
set(CPACK_RPM_PACKAGE_SUGGESTS "doxygen-latex, doxygen-doc, doxygen-gui, graphviz, libclang1")
set(CPACK_RPM_PACKAGE_URL "https://doxygen.org/")
set(CPACK_SET_DESTDIR "OFF")
set(CPACK_SOURCE_GENERATOR "TBZ2;TGZ;TXZ;TZ")
set(CPACK_SOURCE_OUTPUT_CONFIG_FILE "/home/vsc/github/doxygen/Debug/CPackSourceConfig.cmake")
set(CPACK_SOURCE_RPM "OFF")
set(CPACK_SOURCE_TBZ2 "ON")
set(CPACK_SOURCE_TGZ "ON")
set(CPACK_SOURCE_TXZ "ON")
set(CPACK_SOURCE_TZ "ON")
set(CPACK_SOURCE_ZIP "OFF")
set(CPACK_STRIP_FILES "ON")
set(CPACK_SYSTEM_NAME "Linux")
set(CPACK_THREADS "1")
set(CPACK_TOPLEVEL_TAG "Linux")
set(CPACK_WIX_SIZEOF_VOID_P "8")

if(NOT CPACK_PROPERTIES_FILE)
  set(CPACK_PROPERTIES_FILE "/home/vsc/github/doxygen/Debug/CPackProperties.cmake")
endif()

if(EXISTS ${CPACK_PROPERTIES_FILE})
  include(${CPACK_PROPERTIES_FILE})
endif()
