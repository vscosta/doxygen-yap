# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.26

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
CMAKE_BINARY_DIR = /home/vsc/github/doxygen/Debug

# Utility rule file for docs_internal.

# Include any custom commands dependencies for this target.
include doc_internal/CMakeFiles/docs_internal.dir/compiler_depend.make

# Include the progress variables for this target.
include doc_internal/CMakeFiles/docs_internal.dir/progress.make

doc_internal/CMakeFiles/docs_internal: bin/doxygen
doc_internal/CMakeFiles/docs_internal: doc_internal/commands_history.md
doc_internal/CMakeFiles/docs_internal: doc_internal/tags_history.md
doc_internal/CMakeFiles/docs_internal: doc_internal/translator_report.md
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/vsc/github/doxygen/Debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Generating HTML internal documentation."
	cd /home/vsc/github/doxygen/Debug/doc_internal && /usr/bin/cmake -E env VERSION=1.9.8 /home/vsc/github/doxygen/Debug/bin/doxygen

doc_internal/commands_history.md: /home/vsc/github/doxygen/doc_internal/cmds_tags.py
doc_internal/commands_history.md: /home/vsc/github/doxygen/doc_internal/commands_history.md
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/vsc/github/doxygen/Debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Generating commands_history.md"
	cd /home/vsc/github/doxygen/Debug/doc_internal && /usr/bin/python /home/vsc/github/doxygen/doc_internal/cmds_tags.py -cmds /home/vsc/github/doxygen/doc_internal /home/vsc/github/doxygen/doc_internal/commands_history.md /home/vsc/github/doxygen/Debug/doc_internal/commands_history.md

doc_internal/tags_history.md: /home/vsc/github/doxygen/doc_internal/cmds_tags.py
doc_internal/tags_history.md: /home/vsc/github/doxygen/doc_internal/tags_history.md
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/vsc/github/doxygen/Debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Generating tags_history.md"
	cd /home/vsc/github/doxygen/Debug/doc_internal && /usr/bin/python /home/vsc/github/doxygen/doc_internal/cmds_tags.py -tags /home/vsc/github/doxygen/doc_internal /home/vsc/github/doxygen/doc_internal/tags_history.md /home/vsc/github/doxygen/Debug/doc_internal/tags_history.md

doc_internal/translator_report.md: /home/vsc/github/doxygen/VERSION
doc_internal/translator_report.md: /home/vsc/github/doxygen/doc/maintainers.txt
doc_internal/translator_report.md: /home/vsc/github/doxygen/doc/language.tpl
doc_internal/translator_report.md: doc_internal/translator.py
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_am.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_ar.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_bg.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_br.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_ca.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_cn.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_cz.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_de.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_dk.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_en.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_eo.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_es.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_fa.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_fi.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_fr.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_gr.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_hi.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_hr.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_hu.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_id.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_it.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_je.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_jp.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_ke.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_kr.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_lt.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_lv.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_mk.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_nl.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_no.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_pl.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_pt.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_ro.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_ru.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_sc.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_si.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_sk.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_sr.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_sv.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_tr.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_tw.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_ua.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_vi.h
doc_internal/translator_report.md: /home/vsc/github/doxygen/src/translator_za.h
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/vsc/github/doxygen/Debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_4) "Generating translator_report.md"
	cd /home/vsc/github/doxygen/Debug/doc_internal && /usr/bin/python translator.py --doc_internal /home/vsc/github/doxygen

doc_internal/translator.py: /home/vsc/github/doxygen/doc/translator.py
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --blue --bold --progress-dir=/home/vsc/github/doxygen/Debug/CMakeFiles --progress-num=$(CMAKE_PROGRESS_5) "Generating translator.py"
	cd /home/vsc/github/doxygen/Debug/doc_internal && /usr/bin/cmake -E copy /home/vsc/github/doxygen/doc/translator.py /home/vsc/github/doxygen/Debug/doc_internal/

docs_internal: doc_internal/CMakeFiles/docs_internal
docs_internal: doc_internal/commands_history.md
docs_internal: doc_internal/tags_history.md
docs_internal: doc_internal/translator.py
docs_internal: doc_internal/translator_report.md
docs_internal: doc_internal/CMakeFiles/docs_internal.dir/build.make
.PHONY : docs_internal

# Rule to build all files generated by this target.
doc_internal/CMakeFiles/docs_internal.dir/build: docs_internal
.PHONY : doc_internal/CMakeFiles/docs_internal.dir/build

doc_internal/CMakeFiles/docs_internal.dir/clean:
	cd /home/vsc/github/doxygen/Debug/doc_internal && $(CMAKE_COMMAND) -P CMakeFiles/docs_internal.dir/cmake_clean.cmake
.PHONY : doc_internal/CMakeFiles/docs_internal.dir/clean

doc_internal/CMakeFiles/docs_internal.dir/depend:
	cd /home/vsc/github/doxygen/Debug && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/vsc/github/doxygen /home/vsc/github/doxygen/doc_internal /home/vsc/github/doxygen/Debug /home/vsc/github/doxygen/Debug/doc_internal /home/vsc/github/doxygen/Debug/doc_internal/CMakeFiles/docs_internal.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : doc_internal/CMakeFiles/docs_internal.dir/depend

