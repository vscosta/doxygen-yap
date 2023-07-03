file(REMOVE_RECURSE
  "CMakeFiles/docs_internal"
  "commands_history.md"
  "tags_history.md"
  "translator.py"
  "translator_report.md"
)

# Per-language clean rules from dependency scanning.
foreach(lang )
  include(CMakeFiles/docs_internal.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
