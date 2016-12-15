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


SET(CPACK_BINARY_7Z "")
SET(CPACK_BINARY_BUNDLE "")
SET(CPACK_BINARY_CYGWIN "")
SET(CPACK_BINARY_DEB "")
SET(CPACK_BINARY_DRAGNDROP "")
SET(CPACK_BINARY_IFW "")
SET(CPACK_BINARY_NSIS "")
SET(CPACK_BINARY_OSXX11 "")
SET(CPACK_BINARY_PACKAGEMAKER "")
SET(CPACK_BINARY_PRODUCTBUILD "")
SET(CPACK_BINARY_RPM "")
SET(CPACK_BINARY_STGZ "")
SET(CPACK_BINARY_TBZ2 "")
SET(CPACK_BINARY_TGZ "")
SET(CPACK_BINARY_TXZ "")
SET(CPACK_BINARY_TZ "")
SET(CPACK_BINARY_WIX "")
SET(CPACK_BINARY_ZIP "")
SET(CPACK_BUILD_SOURCE_DIRS "/Users/vsc/github/doxygen-yap;/Users/vsc/github/doxygen-yap/xcode")
SET(CPACK_CMAKE_GENERATOR "Xcode")
SET(CPACK_COMPONENT_UNSPECIFIED_HIDDEN "TRUE")
SET(CPACK_COMPONENT_UNSPECIFIED_REQUIRED "TRUE")
SET(CPACK_DEBIAN_PACKAGE_CONFLICTS "graphviz (<< 1.12)")
SET(CPACK_DEBIAN_PACKAGE_DESCRIPTION "Doxygen is the de facto standard tool for generating documentation from annotated C++ sources.
 But many other popular programming languages are supported:
 C, Objective-C, C#, PHP, Java, Python, Fortran, VHDL, Tcl, D (some extent) and IDL (Corba, Microsoft, and UNO/OpenOffice flavors).
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
SET(CPACK_DEBIAN_PACKAGE_HOMEPAGE "http://doxygen.org/")
SET(CPACK_DEBIAN_PACKAGE_MAINTAINER "Matthias Klose <doko@debian.org>")
SET(CPACK_DEBIAN_PACKAGE_SECTION "devel")
SET(CPACK_DEBIAN_PACKAGE_SHLIBDEPS "YES")
SET(CPACK_DEBIAN_PACKAGE_SUGGESTS "doxygen-latex, doxygen-doc, doxygen-gui, graphviz, libclang1")
SET(CPACK_DMG_BACKGROUND_IMAGE "/Users/vsc/github/doxygen-yap/doc/doxygen_logo.eps")
SET(CPACK_DMG_FORMAT "UDBZ")
SET(CPACK_DMG_VOLUME_NAME "doxygen")
SET(CPACK_GENERATOR "TBZ2;TGZ;TXZ;TZ")
SET(CPACK_IGNORE_FILES "/CVS/;/\\.svn/;/\\.bzr/;/\\.hg/;/\\.git/;\\.swp\$;\\.#;/#")
SET(CPACK_INSTALLED_DIRECTORIES "/Users/vsc/github/doxygen-yap;/")
SET(CPACK_INSTALL_CMAKE_PROJECTS "")
SET(CPACK_INSTALL_PREFIX "/usr/local")
SET(CPACK_MODULE_PATH "/Users/vsc/github/doxygen-yap/cmake")
SET(CPACK_NSIS_DISPLAY_NAME "doxygen 1.8.13")
SET(CPACK_NSIS_INSTALLER_ICON_CODE "")
SET(CPACK_NSIS_INSTALLER_MUI_ICON_CODE "")
SET(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")
SET(CPACK_NSIS_MUI_ICON "/Users/vsc/github/doxygen-yap/addon/doxywizard/doxywizard.ico")
SET(CPACK_NSIS_PACKAGE_NAME "doxygen")
SET(CPACK_NSIS_URL_INFO_ABOUT "http://doxygen.org/")
SET(CPACK_OSX_SYSROOT "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.12.sdk")
SET(CPACK_OUTPUT_CONFIG_FILE "/Users/vsc/github/doxygen-yap/xcode/CPackConfig.cmake")
SET(CPACK_PACKAGE_CONTACT "Dimitri van Heesch")
SET(CPACK_PACKAGE_DEFAULT_LOCATION "/")
SET(CPACK_PACKAGE_DESCRIPTION "Doxygen is the de facto standard tool for generating documentation from annotated C++ sources.
 But many other popular programming languages are supported:
 C, Objective-C, C#, PHP, Java, Python, Fortran, VHDL, Tcl, D (some extent) and IDL (Corba, Microsoft, and UNO/OpenOffice flavors).
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
SET(CPACK_PACKAGE_DESCRIPTION_FILE "/usr/local/Cellar/cmake/3.7.0/share/cmake/Templates/CPack.GenericDescription.txt")
SET(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Generate documentation from C, C++, Java, Python and other languages")
SET(CPACK_PACKAGE_FILE_NAME "doxygen-1.8.13-Source")
SET(CPACK_PACKAGE_INSTALL_DIRECTORY "doxygen 1.8.13")
SET(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "doxygen 1.8.13")
SET(CPACK_PACKAGE_NAME "doxygen")
SET(CPACK_PACKAGE_RELOCATABLE "true")
SET(CPACK_PACKAGE_VENDOR "Dimitri van Heesch")
SET(CPACK_PACKAGE_VERSION "1.8.13")
SET(CPACK_PACKAGE_VERSION_MAJOR "0")
SET(CPACK_PACKAGE_VERSION_MINOR "1")
SET(CPACK_PACKAGE_VERSION_PATCH "1")
SET(CPACK_RESOURCE_FILE_LICENSE "/Users/vsc/github/doxygen-yap/LICENSE")
SET(CPACK_RESOURCE_FILE_README "/Users/vsc/github/doxygen-yap/README.md")
SET(CPACK_RESOURCE_FILE_WELCOME "/usr/local/Cellar/cmake/3.7.0/share/cmake/Templates/CPack.GenericWelcome.txt")
SET(CPACK_RPM_PACKAGE_DESCRIPTION "Doxygen is the de facto standard tool for generating documentation from annotated C++ sources.
 But many other popular programming languages are supported:
 C, Objective-C, C#, PHP, Java, Python, Fortran, VHDL, Tcl, D (some extent) and IDL (Corba, Microsoft, and UNO/OpenOffice flavors).
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
SET(CPACK_RPM_PACKAGE_GROUP "Development/Tools")
SET(CPACK_RPM_PACKAGE_LICENSE "GPLv2")
SET(CPACK_RPM_PACKAGE_REQUIRES "/sbin/chkconfig, /bin/mktemp, /bin/rm, /bin/mv, libstdc++ >= 2.96")
SET(CPACK_RPM_PACKAGE_SOURCES "ON")
SET(CPACK_RPM_PACKAGE_SUGGESTS "doxygen-latex, doxygen-doc, doxygen-gui, graphviz, libclang1")
SET(CPACK_RPM_PACKAGE_URL "http://doxygen.org/")
SET(CPACK_SET_DESTDIR "OFF")
SET(CPACK_SOURCE_7Z "")
SET(CPACK_SOURCE_CYGWIN "")
SET(CPACK_SOURCE_GENERATOR "TBZ2;TGZ;TXZ;TZ")
SET(CPACK_SOURCE_IGNORE_FILES "/CVS/;/\\.svn/;/\\.bzr/;/\\.hg/;/\\.git/;\\.swp\$;\\.#;/#")
SET(CPACK_SOURCE_INSTALLED_DIRECTORIES "/Users/vsc/github/doxygen-yap;/")
SET(CPACK_SOURCE_OUTPUT_CONFIG_FILE "/Users/vsc/github/doxygen-yap/xcode/CPackSourceConfig.cmake")
SET(CPACK_SOURCE_PACKAGE_FILE_NAME "doxygen-1.8.13-Source")
SET(CPACK_SOURCE_RPM "OFF")
SET(CPACK_SOURCE_TBZ2 "ON")
SET(CPACK_SOURCE_TGZ "ON")
SET(CPACK_SOURCE_TOPLEVEL_TAG "OSX-Source")
SET(CPACK_SOURCE_TXZ "ON")
SET(CPACK_SOURCE_TZ "ON")
SET(CPACK_SOURCE_ZIP "OFF")
SET(CPACK_STRIP_FILES "")
SET(CPACK_SYSTEM_NAME "OSX")
SET(CPACK_TOPLEVEL_TAG "OSX-Source")
SET(CPACK_WIX_SIZEOF_VOID_P "8")

if(NOT CPACK_PROPERTIES_FILE)
  set(CPACK_PROPERTIES_FILE "/Users/vsc/github/doxygen-yap/xcode/CPackProperties.cmake")
endif()

if(EXISTS ${CPACK_PROPERTIES_FILE})
  include(${CPACK_PROPERTIES_FILE})
endif()
