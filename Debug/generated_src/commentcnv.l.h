static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Scan: return "Scan";
    case SkipString: return "SkipString";
    case SkipChar: return "SkipChar";
    case SComment: return "SComment";
    case CComment: return "CComment";
    case CNComment: return "CNComment";
    case Verbatim: return "Verbatim";
    case VerbatimCode: return "VerbatimCode";
    case ReadLine: return "ReadLine";
    case CondLine: return "CondLine";
    case ReadAliasArgs: return "ReadAliasArgs";
  }
  return "Unknown";
}
