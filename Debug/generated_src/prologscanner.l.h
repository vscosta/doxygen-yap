static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Search: return "Search";
    case SearchMemVars: return "SearchMemVars";
    case TryClassDocString: return "TryClassDocString";
    case TripleComment: return "TripleComment";
    case SkipComment: return "SkipComment";
    case SpecialComment: return "SpecialComment";
    case SWISpecialComment: return "SWISpecialComment";
    case SpecialLineComment: return "SpecialLineComment";
    case SWISpecialLineComment: return "SWISpecialLineComment";
    case SWIQuoted: return "SWIQuoted";
    case SWIInline: return "SWIInline";
    case SWIBold: return "SWIBold";
    case Inline: return "Inline";
    case ExtraCommentArgs: return "ExtraCommentArgs";
    case Head: return "Head";
    case Body: return "Body";
    case HeadOperator: return "HeadOperator";
    case Predinfo: return "Predinfo";
    case Directive: return "Directive";
    case PrepareExportList: return "PrepareExportList";
    case ExportList: return "ExportList";
    case ReExportList: return "ReExportList";
    case Import: return "Import";
    case Metas: return "Metas";
    case DocBlockShortMsg: return "DocBlockShortMsg";
    case Indicator: return "Indicator";
  }
  return "Unknown";
}
