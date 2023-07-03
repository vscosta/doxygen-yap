static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case SkipString: return "SkipString";
    case SkipStringS: return "SkipStringS";
    case SkipVerbString: return "SkipVerbString";
    case SkipCPP: return "SkipCPP";
    case SkipComment: return "SkipComment";
    case SkipCxxComment: return "SkipCxxComment";
    case RemoveSpecialCComment: return "RemoveSpecialCComment";
    case Body: return "Body";
    case FuncCall: return "FuncCall";
    case MemberCall: return "MemberCall";
    case MemberCall2: return "MemberCall2";
    case SkipInits: return "SkipInits";
    case ClassName: return "ClassName";
    case AlignAs: return "AlignAs";
    case AlignAsEnd: return "AlignAsEnd";
    case PackageName: return "PackageName";
    case ClassVar: return "ClassVar";
    case CppCliTypeModifierFollowup: return "CppCliTypeModifierFollowup";
    case Bases: return "Bases";
    case SkipSharp: return "SkipSharp";
    case ReadInclude: return "ReadInclude";
    case TemplDecl: return "TemplDecl";
    case TemplCast: return "TemplCast";
    case CallEnd: return "CallEnd";
    case ObjCMethod: return "ObjCMethod";
    case ObjCParams: return "ObjCParams";
    case ObjCParamType: return "ObjCParamType";
    case ObjCCall: return "ObjCCall";
    case ObjCMName: return "ObjCMName";
    case ObjCSkipStr: return "ObjCSkipStr";
    case ObjCCallComment: return "ObjCCallComment";
    case OldStyleArgs: return "OldStyleArgs";
    case ConceptName: return "ConceptName";
    case UsingName: return "UsingName";
    case RawString: return "RawString";
    case InlineInit: return "InlineInit";
  }
  return "Unknown";
}
