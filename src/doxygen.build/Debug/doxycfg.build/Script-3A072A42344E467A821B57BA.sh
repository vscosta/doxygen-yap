#!/bin/sh
make -C /Users/vsc/github/doxygen/src -f /Users/vsc/github/doxygen/src/CMakeScripts/doxycfg_cmakeRulesBuildPhase.make$CONFIGURATION OBJDIR=$(basename "$OBJECT_FILE_DIR_normal") all
