# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.7

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.7.0/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.7.0/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/vsc/github/doxygen-yap

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/vsc/github/doxygen-yap

# Utility rule file for tests.

# Include the progress variables for this target.
include testing/CMakeFiles/tests.dir/progress.make

testing/CMakeFiles/tests: bin/doxygen
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/Users/vsc/github/doxygen-yap/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Running doxygen tests..."
	cd /Users/vsc/github/doxygen-yap/testing && /usr/local/bin/python /Users/vsc/github/doxygen-yap/testing/runtests.py --all --doxygen /Users/vsc/github/doxygen-yap/bin/doxygen --inputdir /Users/vsc/github/doxygen-yap/testing --outputdir /Users/vsc/github/doxygen-yap/testing

tests: testing/CMakeFiles/tests
tests: testing/CMakeFiles/tests.dir/build.make

.PHONY : tests

# Rule to build all files generated by this target.
testing/CMakeFiles/tests.dir/build: tests

.PHONY : testing/CMakeFiles/tests.dir/build

testing/CMakeFiles/tests.dir/clean:
	cd /Users/vsc/github/doxygen-yap/testing && $(CMAKE_COMMAND) -P CMakeFiles/tests.dir/cmake_clean.cmake
.PHONY : testing/CMakeFiles/tests.dir/clean

testing/CMakeFiles/tests.dir/depend:
	cd /Users/vsc/github/doxygen-yap && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/vsc/github/doxygen-yap /Users/vsc/github/doxygen-yap/testing /Users/vsc/github/doxygen-yap /Users/vsc/github/doxygen-yap/testing /Users/vsc/github/doxygen-yap/testing/CMakeFiles/tests.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : testing/CMakeFiles/tests.dir/depend

