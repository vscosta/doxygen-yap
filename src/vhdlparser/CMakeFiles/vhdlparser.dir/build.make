# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.18

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
CMAKE_COMMAND = /usr/local/Cellar/cmake/3.18.4/bin/cmake

# The command to remove a file.
RM = /usr/local/Cellar/cmake/3.18.4/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/vsc/github/doxygen

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/vsc/github/doxygen/src

# Include any dependencies generated for this target.
include vhdlparser/CMakeFiles/vhdlparser.dir/depend.make

# Include the progress variables for this target.
include vhdlparser/CMakeFiles/vhdlparser.dir/progress.make

# Include the compile flags for this target's objects.
include vhdlparser/CMakeFiles/vhdlparser.dir/flags.make

generated_src/VhdlParser_adj.cc: ../vhdlparser/VhdlParser.cc
generated_src/VhdlParser_adj.cc: ../vhdlparser/vhdl_adj.py
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/Users/vsc/github/doxygen/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Generating ../generated_src/VhdlParser_adj.cc"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /usr/local/bin/python /Users/vsc/github/doxygen/vhdlparser/vhdl_adj.py /Users/vsc/github/doxygen/vhdlparser/VhdlParser.cc /Users/vsc/github/doxygen/src/generated_src/VhdlParser_adj.cc

vhdlparser/CMakeFiles/vhdlparser.dir/CharStream.cc.o: vhdlparser/CMakeFiles/vhdlparser.dir/flags.make
vhdlparser/CMakeFiles/vhdlparser.dir/CharStream.cc.o: ../vhdlparser/CharStream.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/vsc/github/doxygen/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building CXX object vhdlparser/CMakeFiles/vhdlparser.dir/CharStream.cc.o"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/vhdlparser.dir/CharStream.cc.o -c /Users/vsc/github/doxygen/vhdlparser/CharStream.cc

vhdlparser/CMakeFiles/vhdlparser.dir/CharStream.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/vhdlparser.dir/CharStream.cc.i"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/vsc/github/doxygen/vhdlparser/CharStream.cc > CMakeFiles/vhdlparser.dir/CharStream.cc.i

vhdlparser/CMakeFiles/vhdlparser.dir/CharStream.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/vhdlparser.dir/CharStream.cc.s"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/vsc/github/doxygen/vhdlparser/CharStream.cc -o CMakeFiles/vhdlparser.dir/CharStream.cc.s

vhdlparser/CMakeFiles/vhdlparser.dir/ParseException.cc.o: vhdlparser/CMakeFiles/vhdlparser.dir/flags.make
vhdlparser/CMakeFiles/vhdlparser.dir/ParseException.cc.o: ../vhdlparser/ParseException.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/vsc/github/doxygen/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Building CXX object vhdlparser/CMakeFiles/vhdlparser.dir/ParseException.cc.o"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/vhdlparser.dir/ParseException.cc.o -c /Users/vsc/github/doxygen/vhdlparser/ParseException.cc

vhdlparser/CMakeFiles/vhdlparser.dir/ParseException.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/vhdlparser.dir/ParseException.cc.i"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/vsc/github/doxygen/vhdlparser/ParseException.cc > CMakeFiles/vhdlparser.dir/ParseException.cc.i

vhdlparser/CMakeFiles/vhdlparser.dir/ParseException.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/vhdlparser.dir/ParseException.cc.s"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/vsc/github/doxygen/vhdlparser/ParseException.cc -o CMakeFiles/vhdlparser.dir/ParseException.cc.s

vhdlparser/CMakeFiles/vhdlparser.dir/Token.cc.o: vhdlparser/CMakeFiles/vhdlparser.dir/flags.make
vhdlparser/CMakeFiles/vhdlparser.dir/Token.cc.o: ../vhdlparser/Token.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/vsc/github/doxygen/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Building CXX object vhdlparser/CMakeFiles/vhdlparser.dir/Token.cc.o"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/vhdlparser.dir/Token.cc.o -c /Users/vsc/github/doxygen/vhdlparser/Token.cc

vhdlparser/CMakeFiles/vhdlparser.dir/Token.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/vhdlparser.dir/Token.cc.i"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/vsc/github/doxygen/vhdlparser/Token.cc > CMakeFiles/vhdlparser.dir/Token.cc.i

vhdlparser/CMakeFiles/vhdlparser.dir/Token.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/vhdlparser.dir/Token.cc.s"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/vsc/github/doxygen/vhdlparser/Token.cc -o CMakeFiles/vhdlparser.dir/Token.cc.s

vhdlparser/CMakeFiles/vhdlparser.dir/TokenMgrError.cc.o: vhdlparser/CMakeFiles/vhdlparser.dir/flags.make
vhdlparser/CMakeFiles/vhdlparser.dir/TokenMgrError.cc.o: ../vhdlparser/TokenMgrError.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/vsc/github/doxygen/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Building CXX object vhdlparser/CMakeFiles/vhdlparser.dir/TokenMgrError.cc.o"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/vhdlparser.dir/TokenMgrError.cc.o -c /Users/vsc/github/doxygen/vhdlparser/TokenMgrError.cc

vhdlparser/CMakeFiles/vhdlparser.dir/TokenMgrError.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/vhdlparser.dir/TokenMgrError.cc.i"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/vsc/github/doxygen/vhdlparser/TokenMgrError.cc > CMakeFiles/vhdlparser.dir/TokenMgrError.cc.i

vhdlparser/CMakeFiles/vhdlparser.dir/TokenMgrError.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/vhdlparser.dir/TokenMgrError.cc.s"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/vsc/github/doxygen/vhdlparser/TokenMgrError.cc -o CMakeFiles/vhdlparser.dir/TokenMgrError.cc.s

vhdlparser/CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.o: vhdlparser/CMakeFiles/vhdlparser.dir/flags.make
vhdlparser/CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.o: generated_src/VhdlParser_adj.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/vsc/github/doxygen/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_6) "Building CXX object vhdlparser/CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.o"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.o -c /Users/vsc/github/doxygen/src/generated_src/VhdlParser_adj.cc

vhdlparser/CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.i"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/vsc/github/doxygen/src/generated_src/VhdlParser_adj.cc > CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.i

vhdlparser/CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.s"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/vsc/github/doxygen/src/generated_src/VhdlParser_adj.cc -o CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.s

vhdlparser/CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.o: vhdlparser/CMakeFiles/vhdlparser.dir/flags.make
vhdlparser/CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.o: ../vhdlparser/VhdlParserTokenManager.cc
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/Users/vsc/github/doxygen/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_7) "Building CXX object vhdlparser/CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.o"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.o -c /Users/vsc/github/doxygen/vhdlparser/VhdlParserTokenManager.cc

vhdlparser/CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.i"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /Users/vsc/github/doxygen/vhdlparser/VhdlParserTokenManager.cc > CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.i

vhdlparser/CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.s"
	cd /Users/vsc/github/doxygen/src/vhdlparser && /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/c++ $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /Users/vsc/github/doxygen/vhdlparser/VhdlParserTokenManager.cc -o CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.s

# Object files for target vhdlparser
vhdlparser_OBJECTS = \
"CMakeFiles/vhdlparser.dir/CharStream.cc.o" \
"CMakeFiles/vhdlparser.dir/ParseException.cc.o" \
"CMakeFiles/vhdlparser.dir/Token.cc.o" \
"CMakeFiles/vhdlparser.dir/TokenMgrError.cc.o" \
"CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.o" \
"CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.o"

# External object files for target vhdlparser
vhdlparser_EXTERNAL_OBJECTS =

lib/libvhdlparser.a: vhdlparser/CMakeFiles/vhdlparser.dir/CharStream.cc.o
lib/libvhdlparser.a: vhdlparser/CMakeFiles/vhdlparser.dir/ParseException.cc.o
lib/libvhdlparser.a: vhdlparser/CMakeFiles/vhdlparser.dir/Token.cc.o
lib/libvhdlparser.a: vhdlparser/CMakeFiles/vhdlparser.dir/TokenMgrError.cc.o
lib/libvhdlparser.a: vhdlparser/CMakeFiles/vhdlparser.dir/__/generated_src/VhdlParser_adj.cc.o
lib/libvhdlparser.a: vhdlparser/CMakeFiles/vhdlparser.dir/VhdlParserTokenManager.cc.o
lib/libvhdlparser.a: vhdlparser/CMakeFiles/vhdlparser.dir/build.make
lib/libvhdlparser.a: vhdlparser/CMakeFiles/vhdlparser.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/Users/vsc/github/doxygen/src/CMakeFiles --progress-num=$(CMAKE_PROGRESS_8) "Linking CXX static library ../lib/libvhdlparser.a"
	cd /Users/vsc/github/doxygen/src/vhdlparser && $(CMAKE_COMMAND) -P CMakeFiles/vhdlparser.dir/cmake_clean_target.cmake
	cd /Users/vsc/github/doxygen/src/vhdlparser && $(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/vhdlparser.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
vhdlparser/CMakeFiles/vhdlparser.dir/build: lib/libvhdlparser.a

.PHONY : vhdlparser/CMakeFiles/vhdlparser.dir/build

vhdlparser/CMakeFiles/vhdlparser.dir/clean:
	cd /Users/vsc/github/doxygen/src/vhdlparser && $(CMAKE_COMMAND) -P CMakeFiles/vhdlparser.dir/cmake_clean.cmake
.PHONY : vhdlparser/CMakeFiles/vhdlparser.dir/clean

vhdlparser/CMakeFiles/vhdlparser.dir/depend: generated_src/VhdlParser_adj.cc
	cd /Users/vsc/github/doxygen/src && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/vsc/github/doxygen /Users/vsc/github/doxygen/vhdlparser /Users/vsc/github/doxygen/src /Users/vsc/github/doxygen/src/vhdlparser /Users/vsc/github/doxygen/src/vhdlparser/CMakeFiles/vhdlparser.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : vhdlparser/CMakeFiles/vhdlparser.dir/depend
