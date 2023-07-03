static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Initial: return "Initial";
    case Content: return "Content";
    case CDataSection: return "CDataSection";
    case Element: return "Element";
    case Attributes: return "Attributes";
    case AttributeValue: return "AttributeValue";
    case AttrValueStr: return "AttrValueStr";
    case Prolog: return "Prolog";
    case Comment: return "Comment";
  }
  return "Unknown";
}
