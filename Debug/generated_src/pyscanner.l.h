static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Search: return "Search";
    case SearchMemVars: return "SearchMemVars";
    case SearchSkipValue: return "SearchSkipValue";
    case TripleComment: return "TripleComment";
    case SpecialComment: return "SpecialComment";
    case FunctionDec: return "FunctionDec";
    case FunctionParams: return "FunctionParams";
    case FunctionBody: return "FunctionBody";
    case FunctionAnnotation: return "FunctionAnnotation";
    case FunctionTypeAnnotation: return "FunctionTypeAnnotation";
    case FunctionParamDefVal: return "FunctionParamDefVal";
    case ClassDec: return "ClassDec";
    case ClassInheritance: return "ClassInheritance";
    case ClassCaptureIndent: return "ClassCaptureIndent";
    case ClassBody: return "ClassBody";
    case VariableDec: return "VariableDec";
    case VariableEnd: return "VariableEnd";
    case VariableAtom: return "VariableAtom";
    case SingleQuoteString: return "SingleQuoteString";
    case DoubleQuoteString: return "DoubleQuoteString";
    case TripleString: return "TripleString";
    case SingleQuoteStringIgnore: return "SingleQuoteStringIgnore";
    case DoubleQuoteStringIgnore: return "DoubleQuoteStringIgnore";
    case FromMod: return "FromMod";
    case FromModItem: return "FromModItem";
    case Import: return "Import";
  }
  return "Unknown";
}
