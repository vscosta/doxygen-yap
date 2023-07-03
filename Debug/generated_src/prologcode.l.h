static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Program: return "Program";
    case FunctionParams: return "FunctionParams";
    case FunctionParams0: return "FunctionParams0";
    case Body: return "Body";
    case SkipComment: return "SkipComment";
  }
  return "Unknown";
}
