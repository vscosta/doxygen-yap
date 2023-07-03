static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Start: return "Start";
    case CopyArgString: return "CopyArgString";
    case CopyRawString: return "CopyRawString";
    case CopyArgRound: return "CopyArgRound";
    case CopyArgRound2: return "CopyArgRound2";
    case CopyArgSquare: return "CopyArgSquare";
    case CopyArgSharp: return "CopyArgSharp";
    case CopyArgCurly: return "CopyArgCurly";
    case ReadFuncArgType: return "ReadFuncArgType";
    case ReadFuncArgDef: return "ReadFuncArgDef";
    case ReadFuncArgPtr: return "ReadFuncArgPtr";
    case FuncQual: return "FuncQual";
    case ReadDocBlock: return "ReadDocBlock";
    case ReadDocLine: return "ReadDocLine";
    case ReadTypeConstraint: return "ReadTypeConstraint";
    case TrailingReturn: return "TrailingReturn";
  }
  return "Unknown";
}
