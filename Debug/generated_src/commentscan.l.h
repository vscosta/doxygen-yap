static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Comment: return "Comment";
    case PageDocArg1: return "PageDocArg1";
    case PageDocArg2: return "PageDocArg2";
    case RelatesParam1: return "RelatesParam1";
    case ClassDocArg1: return "ClassDocArg1";
    case ClassDocArg2: return "ClassDocArg2";
    case ClassDocArg3: return "ClassDocArg3";
    case CategoryDocArg1: return "CategoryDocArg1";
    case XRefItemParam1: return "XRefItemParam1";
    case XRefItemParam2: return "XRefItemParam2";
    case XRefItemParam3: return "XRefItemParam3";
    case FileDocArg1: return "FileDocArg1";
    case ParamArg1: return "ParamArg1";
    case EnumDocArg1: return "EnumDocArg1";
    case NameSpaceDocArg1: return "NameSpaceDocArg1";
    case PackageDocArg1: return "PackageDocArg1";
    case ConceptDocArg1: return "ConceptDocArg1";
    case GroupDocArg1: return "GroupDocArg1";
    case GroupDocArg2: return "GroupDocArg2";
    case SectionLabel: return "SectionLabel";
    case SectionTitle: return "SectionTitle";
    case SubpageLabel: return "SubpageLabel";
    case SubpageTitle: return "SubpageTitle";
    case FormatBlock: return "FormatBlock";
    case LineParam: return "LineParam";
    case GuardParam: return "GuardParam";
    case GuardParamEnd: return "GuardParamEnd";
    case SkipGuardedSection: return "SkipGuardedSection";
    case SkipInternal: return "SkipInternal";
    case NameParam: return "NameParam";
    case InGroupParam: return "InGroupParam";
    case FnParam: return "FnParam";
    case OverloadParam: return "OverloadParam";
    case InheritParam: return "InheritParam";
    case ExtendsParam: return "ExtendsParam";
    case ReadFormulaShort: return "ReadFormulaShort";
    case ReadFormulaRound: return "ReadFormulaRound";
    case ReadFormulaLong: return "ReadFormulaLong";
    case AnchorLabel: return "AnchorLabel";
    case HtmlComment: return "HtmlComment";
    case HtmlA: return "HtmlA";
    case SkipLang: return "SkipLang";
    case CiteLabel: return "CiteLabel";
    case CopyDoc: return "CopyDoc";
    case GuardExpr: return "GuardExpr";
    case CdataSection: return "CdataSection";
    case Noop: return "Noop";
    case RaiseWarning: return "RaiseWarning";
    case Qualifier: return "Qualifier";
    case CPred: return "CPred";
    case PredFunctor: return "PredFunctor";
    case PredArgs: return "PredArgs";
    case PredInfo: return "PredInfo";
    case SWIInline: return "SWIInline";
  }
  return "Unknown";
}
