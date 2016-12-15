# Install script for directory: /Users/vsc/github/doxygen-yap

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/Users/vsc/github/doxygen-yap/xcode/libmd5/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/qtools/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/vhdlparser/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/src/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/examples/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/doc/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/addon/doxmlparser/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/addon/doxyapp/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/addon/doxysearch/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/addon/doxywizard/cmake_install.cmake")
  include("/Users/vsc/github/doxygen-yap/xcode/testing/cmake_install.cmake")

endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "/Users/vsc/github/doxygen-yap/xcode/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
