#!/bin/sh
make -C /Users/vsc/github/doxygen/src -f /Users/vsc/github/doxygen/src/CMakeScripts/doxymain_cmakeRulesBuildPhase.make$CONFIGURATION OBJDIR=$(basename "$OBJECT_FILE_DIR_normal") all
