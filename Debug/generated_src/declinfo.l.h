static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Start: return "Start";
    case Template: return "Template";
    case ReadArgs: return "ReadArgs";
    case Operator: return "Operator";
    case DeclType: return "DeclType";
    case ReadExceptions: return "ReadExceptions";
  }
  return "Unknown";
}
