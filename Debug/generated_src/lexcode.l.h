static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case DefSection: return "DefSection";
    case DefSectionLine: return "DefSectionLine";
    case RulesSectionInit: return "RulesSectionInit";
    case RulesPattern: return "RulesPattern";
    case RulesDouble: return "RulesDouble";
    case RulesRoundDouble: return "RulesRoundDouble";
    case RulesSquare: return "RulesSquare";
    case RulesRoundSquare: return "RulesRoundSquare";
    case RulesRound: return "RulesRound";
    case RulesRoundQuest: return "RulesRoundQuest";
    case UserSection: return "UserSection";
    case TopSection: return "TopSection";
    case LiteralSection: return "LiteralSection";
    case COMMENT: return "COMMENT";
    case SkipCurly: return "SkipCurly";
    case SkipCurlyEndDoc: return "SkipCurlyEndDoc";
    case PreLineCtrl: return "PreLineCtrl";
    case DocLine: return "DocLine";
    case DocBlock: return "DocBlock";
    case DocCopyBlock: return "DocCopyBlock";
    case SkipString: return "SkipString";
    case RawString: return "RawString";
    case SkipComment: return "SkipComment";
    case SkipCxxComment: return "SkipCxxComment";
    case Comment: return "Comment";
  }
  return "Unknown";
}
