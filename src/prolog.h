/* ----------------------------------------------------------------- */


class Literal {
public:
    typedef  enum {
        PL_NONE = 0x0,
        PL_ATOMIC = 0x1,
        PL_ATOM = 0x2,
        PL_GOAL = 0x4,
        PL_ENTER_BRA = 0x8,
        PL_ENTER_SQB = 0x10,
        PL_ENTER_CRB = 0x20,
        PL_ENTER_GOAL = 0x40,
        PL_ENTER_COMPOUND = 0x80,
        PL_INNER_BRA = 0x100,
        PL_INNER_SQB = 0x200,
        PL_INNER_CRB = 0x400,
        PL_COMPOUND = 0x800,
        PL_ENTER_MODULE = 0x1000
    } token_t ;

    QCString n, m;
    uint a;
    token_t t;

    Literal(QCString source_module) {

        t = Literal::PL_NONE;
        n = "";
        m =  source_module;
        a = 0;
    };

    Literal(token_t t0, QCString m0, QCString n0, uint a0) {
        t = t0;
        n = n0;
        m = m0;
        a = a0;
    }

};

class Clause {
public:
    typedef enum {
        CLI_NONE,
        CLI_DIRECTIVE,
        CLI_HEAD,
        CLI_NECK,
        CLI_BODY,
        FLIT_COMPLETED
    } state_t;
    state_t state;
    QCString text;
    QCString n;
    QCString m;
    uint a;
    int ctx; //> YY_START
    std::vector<Literal> q;

    Clause(QCString current_module) {

        q = {};
        state = CLI_NONE;
        m = current_module;
        text = n = "";
        a = 0;
    };

    Clause() {
        q = {};
        state = CLI_NONE;
        m = "prolog";
        text = n = "";
        a = 0;
    };

    void reset(QCString current_module)
    {
        state = CLI_NONE;
        q = {};
        m = current_module;
        text = n = "";
        a = 0;
    };

    int eval();
};


extern StringUnorderedMap g_foreignCache;
extern StringUnorderedMap g_predNameCache;

extern bool normalizePredName__(QCString curMod, const char *input,
                                QCString &omod, QCString &oname, uint &arity);


inline bool isIndicator(QCString src) {
    if (src.isEmpty())
        return false;
    int i;
    if ((i = src.findRev('/')) < 0)
        return false;
    bool ok = false;
    uint a = src.right(src.length()-i-1).toUInt(&ok);
    return ok && a< 32;
}


class Pred
{
public:
    QCString m, n, foreign;
    unsigned int a;

    Pred(QCString s, QCString current_module);


    Pred(QCString m0, QCString n0, uint a0, QCString *foreigner  = nullptr)
    {
        n = *new QCString( n0);
        m = *new QCString(m0);
        a = a0;
    }


    QCString link()
    {
//      if (m == g_current_module_name || m == "prolog")
//          return n+"/"+QCString().setNum(a);
//      else
return n+"_"+QCString().setNum(a);
    }

    QCString title(QCString current_module)
    {

        // if (m == current_module || m == "prolog")
        //     return n+"/"+QCString().setNum(a);
       return  n + "/" + QCString().setNum(a);
    }

    QCString predName(QCString current_module)
    {
       // if (m == current_module  || m == "prolog")
            return n+"/"+QCString().setNum(a);
//        else
  //          return m+":"+n+"_"+QCString().setNum(a);
    }


    QCString label(QCString mod) {
        return title(mod);
    }
};

