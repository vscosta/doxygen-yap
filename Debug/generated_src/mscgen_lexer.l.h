static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case IN_COMMENT: return "IN_COMMENT";
    case BODY: return "BODY";
  }
  return "Unknown";
}
