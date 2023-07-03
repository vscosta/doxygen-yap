static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Start: return "Start";
    case SkipInvalid: return "SkipInvalid";
    case GetString: return "GetString";
    case GetStrList: return "GetStrList";
    case Include: return "Include";
    case StoreRepl: return "StoreRepl";
  }
  return "Unknown";
}
