static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case St_Para: return "St_Para";
    case St_Comment: return "St_Comment";
    case St_Title: return "St_Title";
    case St_TitleN: return "St_TitleN";
    case St_TitleQ: return "St_TitleQ";
    case St_TitleA: return "St_TitleA";
    case St_TitleV: return "St_TitleV";
    case St_Code: return "St_Code";
    case St_iCode: return "St_iCode";
    case St_CodeOpt: return "St_CodeOpt";
    case St_iCodeOpt: return "St_iCodeOpt";
    case St_XmlCode: return "St_XmlCode";
    case St_HtmlOnly: return "St_HtmlOnly";
    case St_HtmlOnlyOption: return "St_HtmlOnlyOption";
    case St_ManOnly: return "St_ManOnly";
    case St_LatexOnly: return "St_LatexOnly";
    case St_RtfOnly: return "St_RtfOnly";
    case St_XmlOnly: return "St_XmlOnly";
    case St_DbOnly: return "St_DbOnly";
    case St_Verbatim: return "St_Verbatim";
    case St_iVerbatim: return "St_iVerbatim";
    case St_ILiteral: return "St_ILiteral";
    case St_ILiteralOpt: return "St_ILiteralOpt";
    case St_Dot: return "St_Dot";
    case St_Msc: return "St_Msc";
    case St_PlantUMLOpt: return "St_PlantUMLOpt";
    case St_PlantUML: return "St_PlantUML";
    case St_Param: return "St_Param";
    case St_XRefItem: return "St_XRefItem";
    case St_XRefItem2: return "St_XRefItem2";
    case St_File: return "St_File";
    case St_Pattern: return "St_Pattern";
    case St_Link: return "St_Link";
    case St_Cite: return "St_Cite";
    case St_DoxyConfig: return "St_DoxyConfig";
    case St_Ref: return "St_Ref";
    case St_Ref2: return "St_Ref2";
    case St_IntRef: return "St_IntRef";
    case St_Text: return "St_Text";
    case St_SkipTitle: return "St_SkipTitle";
    case St_Anchor: return "St_Anchor";
    case St_Snippet: return "St_Snippet";
    case St_SetScope: return "St_SetScope";
    case St_SetScopeEnd: return "St_SetScopeEnd";
    case St_Options: return "St_Options";
    case St_Block: return "St_Block";
    case St_Emoji: return "St_Emoji";
    case St_ILine: return "St_ILine";
    case St_ShowDate: return "St_ShowDate";
    case St_Sections: return "St_Sections";
    case St_SecLabel1: return "St_SecLabel1";
    case St_SecLabel2: return "St_SecLabel2";
    case St_SecTitle: return "St_SecTitle";
    case St_SecSkip: return "St_SecSkip";
    case St_QuotedString: return "St_QuotedString";
    case St_QuotedContent: return "St_QuotedContent";
  }
  return "Unknown";
}
