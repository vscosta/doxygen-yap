static const char *stateToString(int state)
{
  switch(state)
  {
    case INITIAL: return "INITIAL";
    case Subprog: return "Subprog";
    case SubprogPrefix: return "SubprogPrefix";
    case Parameterlist: return "Parameterlist";
    case SubprogBody: return "SubprogBody";
    case SubprogBodyContains: return "SubprogBodyContains";
    case Start: return "Start";
    case Comment: return "Comment";
    case Module: return "Module";
    case Program: return "Program";
    case ModuleBody: return "ModuleBody";
    case ModuleBodyContains: return "ModuleBodyContains";
    case AttributeList: return "AttributeList";
    case Variable: return "Variable";
    case Initialization: return "Initialization";
    case ArrayInitializer: return "ArrayInitializer";
    case Enum: return "Enum";
    case Typedef: return "Typedef";
    case TypedefBody: return "TypedefBody";
    case TypedefBodyContains: return "TypedefBodyContains";
    case InterfaceBody: return "InterfaceBody";
    case StrIgnore: return "StrIgnore";
    case String: return "String";
    case Use: return "Use";
    case UseOnly: return "UseOnly";
    case ModuleProcedure: return "ModuleProcedure";
    case Prepass: return "Prepass";
    case DocBlock: return "DocBlock";
    case DocBackLine: return "DocBackLine";
    case BlockData: return "BlockData";
    case Prototype: return "Prototype";
    case PrototypeSubprog: return "PrototypeSubprog";
    case PrototypeArgs: return "PrototypeArgs";
  }
  return "Unknown";
}
