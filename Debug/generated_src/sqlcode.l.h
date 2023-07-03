static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case COMMENT: return "COMMENT";
  }
  return "Unknown";
}
