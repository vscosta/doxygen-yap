# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.22

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/vsc/github/doxygen

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/vsc/github/doxygen

# Utility rule file for generate_configvalues_header.

# Include any custom commands dependencies for this target.
include src/CMakeFiles/generate_configvalues_header.dir/compiler_depend.make

# Include the progress variables for this target.
include src/CMakeFiles/generate_configvalues_header.dir/progress.make

src/CMakeFiles/generate_configvalues_header: generated_src/configvalues.h

generated_src/configvalues.h: src/config.xml
generated_src/configvalues.h: src/configgen.py
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/vsc/github/doxygen/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Generating ../generated_src/configvalues.h"
	cd /home/vsc/github/doxygen/src && /usr/bin/python /home/vsc/github/doxygen/src/configgen.py -maph /home/vsc/github/doxygen/src/config.xml > /home/vsc/github/doxygen/generated_src/configvalues.h

generate_configvalues_header: generated_src/configvalues.h
generate_configvalues_header: src/CMakeFiles/generate_configvalues_header
generate_configvalues_header: src/CMakeFiles/generate_configvalues_header.dir/build.make
.PHONY : generate_configvalues_header

# Rule to build all files generated by this target.
src/CMakeFiles/generate_configvalues_header.dir/build: generate_configvalues_header
.PHONY : src/CMakeFiles/generate_configvalues_header.dir/build

src/CMakeFiles/generate_configvalues_header.dir/clean:
	cd /home/vsc/github/doxygen/src && $(CMAKE_COMMAND) -P CMakeFiles/generate_configvalues_header.dir/cmake_clean.cmake
.PHONY : src/CMakeFiles/generate_configvalues_header.dir/clean

src/CMakeFiles/generate_configvalues_header.dir/depend:
	cd /home/vsc/github/doxygen && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/vsc/github/doxygen /home/vsc/github/doxygen/src /home/vsc/github/doxygen /home/vsc/github/doxygen/src /home/vsc/github/doxygen/src/CMakeFiles/generate_configvalues_header.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : src/CMakeFiles/generate_configvalues_header.dir/depend
