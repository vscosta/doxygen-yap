static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Body: return "Body";
    case FunctionDec: return "FunctionDec";
    case FunctionParams: return "FunctionParams";
    case ClassDec: return "ClassDec";
    case ClassInheritance: return "ClassInheritance";
    case Suite: return "Suite";
    case SuiteCaptureIndent: return "SuiteCaptureIndent";
    case SuiteStart: return "SuiteStart";
    case SuiteMaintain: return "SuiteMaintain";
    case SingleQuoteString: return "SingleQuoteString";
    case DoubleQuoteString: return "DoubleQuoteString";
    case TripleString: return "TripleString";
    case DocBlock: return "DocBlock";
  }
  return "Unknown";
}
