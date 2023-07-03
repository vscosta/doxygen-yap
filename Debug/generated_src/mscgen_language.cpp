/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 1 "mscgen_language.y"

/***************************************************************************
 *
 * $Id: language.y 175 2011-02-06 21:07:43Z Michael.McTernan $
 *
 * Grammar and parser for the mscgen language.
 * Copyright (C) 2009 Michael C McTernan, Michael.McTernan.2001@cs.bris.ac.uk
 *
 * This file is part of msclib.
 *
 * Msc is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * Msclib is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Foobar; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 ***************************************************************************/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "mscgen_lexer.h"
#include "mscgen_safe.h"
#include "mscgen_msc.h"

/* Lexer prototypes to prevent compiler warnings */
int yylex(void);
int yylex_destroy(void);

/* Use verbose error reporting such that the expected token names are dumped */
#define YYERROR_VERBOSE

/* Name of parameter that is passed to yyparse() */
#define YYPARSE_PARAM yyparse_result

#define YYMALLOC malloc_s

/* yyerror
 *  Error handling function.  The TOK_XXX names are substituted for more
 *  understandable values that make more sense to the user.
 */
void yyerror(void *unused, const char *str)
{
    static const char *tokNames[] = { "TOK_OCBRACKET",          "TOK_CCBRACKET",
                                      "TOK_OSBRACKET",          "TOK_CSBRACKET",
                                      "TOK_REL_DOUBLE_TO",      "TOK_REL_DOUBLE_FROM",
                                      "TOK_REL_SIG_TO",         "TOK_REL_SIG_FROM",
                                      "TOK_REL_METHOD_TO",      "TOK_REL_METHOD_FROM",
                                      "TOK_REL_RETVAL_TO",      "TOK_REL_RETVAL_FROM",
                                      "TOK_REL_CALLBACK_TO",    "TOK_REL_CALLBACK_FROM",
                                      "TOK_REL_SIG",            "TOK_REL_METHOD",
                                      "TOK_REL_RETVAL",         "TOK_REL_DOUBLE",
                                      "TOK_EQUAL",              "TOK_COMMA",
                                      "TOK_SEMICOLON",          "TOK_MSC",
                                      "TOK_ATTR_LABEL",         "TOK_ATTR_URL",
                                      "TOK_ATTR_IDURL",         "TOK_ATTR_ID",
                                      "TOK_ATTR_LINE_COLOUR",   "TOK_ATTR_TEXT_COLOUR",
                                      "TOK_SPECIAL_ARC",        "TOK_UNKNOWN",
                                      "TOK_STRING",             "TOK_QSTRING",
                                      "TOK_OPT_HSCALE",         "TOK_ASTERISK",
                                      "TOK_OPT_WIDTH",          "TOK_ARC_BOX",
                                      "TOK_ARC_ABOX",           "TOK_ARC_RBOX",
                                      "TOK_ATTR_TEXT_BGCOLOUR", "TOK_ATTR_ARC_TEXT_BGCOLOUR",
                                      "TOK_REL_LOSS_TO",        "TOK_REL_LOSS_FROM",
                                      "TOK_OPT_ARCGRADIENT",    "TOK_ATTR_ARC_SKIP",
                                      "TOK_OPT_WORDWRAPARCS",   "TOK_REL_NOTE" };

    static const char *tokRepl[] =  { "'{'",             "'}'",
                                      "'['",             "']'",
                                      "':>'",            "'<:'",
                                      "'->'",            "'<-'",
                                      "'=>'",            "'<='",
                                      "'>>'",            "'<<'",
                                      "'=>>'",           "'<<='",
                                      "'--'",            "'=='",
                                      "'..'",            "'::'",
                                      "'='",             "','",
                                      "';'",             "'msc'",
                                      "'label'",         "'url'",
                                      "'idurl'",         "'id'",
                                      "'linecolour'",    "'textcolour'",
                                      "'...', '---'",    "characters",
                                      "'string'",        "'quoted string'",
                                      "'hscale'",        "'*'",
                                      "'width'",         "'box'",
                                      "'abox'",          "'rbox'",
                                      "'textbgcolour'",  "'arctextbgcolor'",
                                      "'-x'",            "'x-'",
                                      "'arcgradient'",   "'arcskip'",
                                      "'wordwraparcs'",  "'note'" };

    static const int tokArrayLen = sizeof(tokNames) / sizeof(char *);

    char *s, *line;
    int   t;

    /* Print standard message part */
    fprintf(stderr, "Error detected at line %lu: ", lex_getlinenum());

    /* Search for TOK */
    s = (char *)strstr(str, "TOK_");
    while(s != NULL)
    {
        int found = 0;

        /* Print out message until start of the token is found */
        while(str < s)
        {
            fprintf(stderr, "%c", *str);
            str++;
        }

        /* Look for the token name */
        for(t = 0; t < tokArrayLen && !found; t++)
        {
            if(strncmp(tokNames[t], str, strlen(tokNames[t])) == 0)
            {
                /* Dump the replacement string */
                fprintf(stderr, "%s", tokRepl[t]);

                /* Skip the token name */
                str += strlen(tokNames[t]);

                /* Exit the loop */
                found = 1;
            }
        }

        /* Check if a replacement was found */
        if(!found)
        {
            /* Dump the next char and skip it so that TOK doesn't match again */
            fprintf(stderr, "%c", *str);
            str++;
        }

        s = (char *)strstr(str, "TOK_");
    }

    fprintf(stderr, "%s.\n", str);

    line = lex_getline();
    if(line != NULL)
    {
        fprintf(stderr, "> %s\n", line);

        /* If the input line contains a 'lost arc', print a helpful note since
         *  without whitespace, this can confuse the lexer.
         */
        if(strstr(line, "x-") != NULL)
        {
            fprintf(stderr, "\nNote: This input line contains 'x-' which has special meaning as a \n"
                            "      'lost message' arc, but may not have been recognised as such if it\n"
                            "      is preceded by other letters or numbers.  Please use double-quoted\n"
                            "      strings for tokens before 'x-', or insert a preceding whitespace if\n"
                            "      this is what you intend.\n");
        }
    }
    else
    {
        fprintf(stderr, ".\n");
    }
}

int yywrap()
{
    return 1;
}


char *removeEscapes(char *in)
{
    const uint16_t l = (uint16_t)strlen(in);
    char          *r = (char *)malloc_s(l + 1);
    uint16_t       t, u;

    for(t = u = 0; t < l; t++)
    {
        r[u] = in[t];
        if(in[t] != '\\' || in[t + 1] != '\"')
        {
            u++;
        }
    }

    r[u] = '\0';

    free(in);

    return r;
}

extern FILE *yyin;
extern int   yyparse (void *YYPARSE_PARAM);


Msc MscParse(FILE *in)
{
    Msc m;

    yyin = in;

    lex_resetparser();
    /* Parse, and check that no errors are found */
    if(yyparse((void *)&m) != 0)
    {
        m = NULL;
    }

    lex_destroy();
    yylex_destroy();

    return m;
}



#line 298 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "mscgen_language.hpp"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_TOK_STRING = 3,                 /* TOK_STRING  */
  YYSYMBOL_TOK_QSTRING = 4,                /* TOK_QSTRING  */
  YYSYMBOL_TOK_EQUAL = 5,                  /* TOK_EQUAL  */
  YYSYMBOL_TOK_COMMA = 6,                  /* TOK_COMMA  */
  YYSYMBOL_TOK_SEMICOLON = 7,              /* TOK_SEMICOLON  */
  YYSYMBOL_TOK_OCBRACKET = 8,              /* TOK_OCBRACKET  */
  YYSYMBOL_TOK_CCBRACKET = 9,              /* TOK_CCBRACKET  */
  YYSYMBOL_TOK_OSBRACKET = 10,             /* TOK_OSBRACKET  */
  YYSYMBOL_TOK_CSBRACKET = 11,             /* TOK_CSBRACKET  */
  YYSYMBOL_TOK_MSC = 12,                   /* TOK_MSC  */
  YYSYMBOL_TOK_ATTR_LABEL = 13,            /* TOK_ATTR_LABEL  */
  YYSYMBOL_TOK_ATTR_URL = 14,              /* TOK_ATTR_URL  */
  YYSYMBOL_TOK_ATTR_ID = 15,               /* TOK_ATTR_ID  */
  YYSYMBOL_TOK_ATTR_IDURL = 16,            /* TOK_ATTR_IDURL  */
  YYSYMBOL_TOK_ATTR_LINE_COLOUR = 17,      /* TOK_ATTR_LINE_COLOUR  */
  YYSYMBOL_TOK_ATTR_TEXT_COLOUR = 18,      /* TOK_ATTR_TEXT_COLOUR  */
  YYSYMBOL_TOK_ATTR_TEXT_BGCOLOUR = 19,    /* TOK_ATTR_TEXT_BGCOLOUR  */
  YYSYMBOL_TOK_ATTR_ARC_LINE_COLOUR = 20,  /* TOK_ATTR_ARC_LINE_COLOUR  */
  YYSYMBOL_TOK_ATTR_ARC_TEXT_COLOUR = 21,  /* TOK_ATTR_ARC_TEXT_COLOUR  */
  YYSYMBOL_TOK_ATTR_ARC_TEXT_BGCOLOUR = 22, /* TOK_ATTR_ARC_TEXT_BGCOLOUR  */
  YYSYMBOL_TOK_REL_LOSS_TO = 23,           /* TOK_REL_LOSS_TO  */
  YYSYMBOL_TOK_REL_LOSS_FROM = 24,         /* TOK_REL_LOSS_FROM  */
  YYSYMBOL_TOK_REL_SIG_BI = 25,            /* TOK_REL_SIG_BI  */
  YYSYMBOL_TOK_REL_SIG_TO = 26,            /* TOK_REL_SIG_TO  */
  YYSYMBOL_TOK_REL_SIG_FROM = 27,          /* TOK_REL_SIG_FROM  */
  YYSYMBOL_TOK_REL_METHOD_BI = 28,         /* TOK_REL_METHOD_BI  */
  YYSYMBOL_TOK_REL_METHOD_TO = 29,         /* TOK_REL_METHOD_TO  */
  YYSYMBOL_TOK_REL_METHOD_FROM = 30,       /* TOK_REL_METHOD_FROM  */
  YYSYMBOL_TOK_REL_RETVAL_BI = 31,         /* TOK_REL_RETVAL_BI  */
  YYSYMBOL_TOK_REL_RETVAL_TO = 32,         /* TOK_REL_RETVAL_TO  */
  YYSYMBOL_TOK_REL_RETVAL_FROM = 33,       /* TOK_REL_RETVAL_FROM  */
  YYSYMBOL_TOK_REL_DOUBLE_BI = 34,         /* TOK_REL_DOUBLE_BI  */
  YYSYMBOL_TOK_REL_DOUBLE_TO = 35,         /* TOK_REL_DOUBLE_TO  */
  YYSYMBOL_TOK_REL_DOUBLE_FROM = 36,       /* TOK_REL_DOUBLE_FROM  */
  YYSYMBOL_TOK_REL_CALLBACK_BI = 37,       /* TOK_REL_CALLBACK_BI  */
  YYSYMBOL_TOK_REL_CALLBACK_TO = 38,       /* TOK_REL_CALLBACK_TO  */
  YYSYMBOL_TOK_REL_CALLBACK_FROM = 39,     /* TOK_REL_CALLBACK_FROM  */
  YYSYMBOL_TOK_REL_BOX = 40,               /* TOK_REL_BOX  */
  YYSYMBOL_TOK_REL_ABOX = 41,              /* TOK_REL_ABOX  */
  YYSYMBOL_TOK_REL_RBOX = 42,              /* TOK_REL_RBOX  */
  YYSYMBOL_TOK_REL_NOTE = 43,              /* TOK_REL_NOTE  */
  YYSYMBOL_TOK_SPECIAL_ARC = 44,           /* TOK_SPECIAL_ARC  */
  YYSYMBOL_TOK_OPT_HSCALE = 45,            /* TOK_OPT_HSCALE  */
  YYSYMBOL_TOK_OPT_WIDTH = 46,             /* TOK_OPT_WIDTH  */
  YYSYMBOL_TOK_OPT_ARCGRADIENT = 47,       /* TOK_OPT_ARCGRADIENT  */
  YYSYMBOL_TOK_OPT_WORDWRAPARCS = 48,      /* TOK_OPT_WORDWRAPARCS  */
  YYSYMBOL_TOK_ASTERISK = 49,              /* TOK_ASTERISK  */
  YYSYMBOL_TOK_UNKNOWN = 50,               /* TOK_UNKNOWN  */
  YYSYMBOL_TOK_REL_SIG = 51,               /* TOK_REL_SIG  */
  YYSYMBOL_TOK_REL_METHOD = 52,            /* TOK_REL_METHOD  */
  YYSYMBOL_TOK_REL_RETVAL = 53,            /* TOK_REL_RETVAL  */
  YYSYMBOL_TOK_REL_DOUBLE = 54,            /* TOK_REL_DOUBLE  */
  YYSYMBOL_TOK_ATTR_ARC_SKIP = 55,         /* TOK_ATTR_ARC_SKIP  */
  YYSYMBOL_YYACCEPT = 56,                  /* $accept  */
  YYSYMBOL_msc = 57,                       /* msc  */
  YYSYMBOL_optlist = 58,                   /* optlist  */
  YYSYMBOL_opt = 59,                       /* opt  */
  YYSYMBOL_optval = 60,                    /* optval  */
  YYSYMBOL_entitylist = 61,                /* entitylist  */
  YYSYMBOL_entity = 62,                    /* entity  */
  YYSYMBOL_arclist = 63,                   /* arclist  */
  YYSYMBOL_arc = 64,                       /* arc  */
  YYSYMBOL_arcrel = 65,                    /* arcrel  */
  YYSYMBOL_relation_box = 66,              /* relation_box  */
  YYSYMBOL_relation_line = 67,             /* relation_line  */
  YYSYMBOL_relation_bi = 68,               /* relation_bi  */
  YYSYMBOL_relation_to = 69,               /* relation_to  */
  YYSYMBOL_relation_from = 70,             /* relation_from  */
  YYSYMBOL_attrlist = 71,                  /* attrlist  */
  YYSYMBOL_attr = 72,                      /* attr  */
  YYSYMBOL_attrval = 73,                   /* attrval  */
  YYSYMBOL_string = 74                     /* string  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  4
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   129

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  56
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  19
/* YYNRULES -- Number of rules.  */
#define YYNRULES  68
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  102

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   310


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   290,   290,   296,   303,   304,   309,   314,   314,   314,
     314,   316,   320,   327,   331,   337,   341,   345,   354,   358,
     360,   364,   368,   374,   378,   384,   388,   392,   397,   397,
     397,   397,   398,   398,   398,   398,   399,   399,   399,   399,
     399,   400,   400,   400,   400,   400,   400,   401,   401,   401,
     401,   401,   401,   403,   404,   409,   414,   414,   414,   414,
     415,   415,   415,   416,   416,   416,   417,   420,   424
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "TOK_STRING",
  "TOK_QSTRING", "TOK_EQUAL", "TOK_COMMA", "TOK_SEMICOLON",
  "TOK_OCBRACKET", "TOK_CCBRACKET", "TOK_OSBRACKET", "TOK_CSBRACKET",
  "TOK_MSC", "TOK_ATTR_LABEL", "TOK_ATTR_URL", "TOK_ATTR_ID",
  "TOK_ATTR_IDURL", "TOK_ATTR_LINE_COLOUR", "TOK_ATTR_TEXT_COLOUR",
  "TOK_ATTR_TEXT_BGCOLOUR", "TOK_ATTR_ARC_LINE_COLOUR",
  "TOK_ATTR_ARC_TEXT_COLOUR", "TOK_ATTR_ARC_TEXT_BGCOLOUR",
  "TOK_REL_LOSS_TO", "TOK_REL_LOSS_FROM", "TOK_REL_SIG_BI",
  "TOK_REL_SIG_TO", "TOK_REL_SIG_FROM", "TOK_REL_METHOD_BI",
  "TOK_REL_METHOD_TO", "TOK_REL_METHOD_FROM", "TOK_REL_RETVAL_BI",
  "TOK_REL_RETVAL_TO", "TOK_REL_RETVAL_FROM", "TOK_REL_DOUBLE_BI",
  "TOK_REL_DOUBLE_TO", "TOK_REL_DOUBLE_FROM", "TOK_REL_CALLBACK_BI",
  "TOK_REL_CALLBACK_TO", "TOK_REL_CALLBACK_FROM", "TOK_REL_BOX",
  "TOK_REL_ABOX", "TOK_REL_RBOX", "TOK_REL_NOTE", "TOK_SPECIAL_ARC",
  "TOK_OPT_HSCALE", "TOK_OPT_WIDTH", "TOK_OPT_ARCGRADIENT",
  "TOK_OPT_WORDWRAPARCS", "TOK_ASTERISK", "TOK_UNKNOWN", "TOK_REL_SIG",
  "TOK_REL_METHOD", "TOK_REL_RETVAL", "TOK_REL_DOUBLE",
  "TOK_ATTR_ARC_SKIP", "$accept", "msc", "optlist", "opt", "optval",
  "entitylist", "entity", "arclist", "arc", "arcrel", "relation_box",
  "relation_line", "relation_bi", "relation_to", "relation_from",
  "attrlist", "attr", "attrval", "string", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-36)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-1)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int8 yypact[] =
{
      -6,    35,    48,    15,   -36,   -36,   -36,   -36,   -36,   -36,
     -36,    16,   -36,     3,    34,    40,   -36,   -10,    42,    42,
      42,     8,    11,   -36,    47,   -36,    40,   -36,    90,    49,
     -36,    55,    59,   -36,   -36,   -36,   -36,   -36,   -36,   -36,
     -36,   -36,   -36,   -36,    -1,   -36,    53,     8,   -36,   -36,
     -36,   -36,   -36,   -36,    42,     8,    -2,    11,   -36,   -36,
     -36,   -36,   -36,   -36,   -36,   -36,   -36,   -36,   -36,   -36,
     -36,   -36,   -36,   -36,   -36,   -36,   -36,    42,    42,    42,
      10,    42,    11,   -36,    42,    61,   -36,   -36,   -36,   -36,
      28,   -36,   -36,   -36,   -36,   -36,   -36,   -36,   -36,     0,
     -36,   -36
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       0,     0,     0,     0,     1,    68,    67,     7,     8,     9,
      10,     0,     4,     0,     0,    11,    13,     0,     0,     0,
       0,     0,     0,     5,     0,     6,    12,    20,     0,     0,
      15,    19,     0,    56,    57,    58,    59,    60,    61,    62,
      63,    64,    65,    66,     0,    53,     0,     0,    52,    47,
      48,    49,    51,    50,     0,     0,     0,     0,    46,    36,
      41,    37,    42,    38,    43,    40,    45,    39,    44,    28,
      29,    30,    31,    32,    33,    34,    35,     0,     0,     0,
       0,     0,     0,    14,     0,     0,    27,    17,     3,    16,
       0,    21,    24,    22,    26,    23,    25,    54,    55,     0,
      18,     2
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -36,   -36,   -36,    52,   -36,    54,    50,    24,   -35,   -36,
     -36,   -36,   -36,   -36,    41,    22,    21,   -36,    -3
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
       0,     2,    11,    12,    13,    14,    15,    29,    30,    31,
      77,    78,    79,    80,    54,    44,    45,    46,    32
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int8 yytable[] =
{
      16,     5,     6,     5,     6,    82,     1,    88,    19,   101,
      83,     5,     6,     5,     6,    16,    25,    16,     5,     6,
      87,    89,    17,    18,    33,    34,    35,    36,    37,    38,
      39,    40,    41,    42,    82,     7,     8,     9,    10,   100,
      20,    21,    27,     3,    27,     5,     6,    28,     4,    28,
      22,    86,    27,    20,    47,    55,    56,    28,    84,    94,
       7,     8,     9,    10,    89,    57,    43,    55,    99,    23,
      26,    85,    24,    81,    91,    92,    93,    95,    96,    90,
       0,    98,    58,    48,    59,    60,    49,    61,    62,    50,
      63,    64,    51,    65,    66,    52,    67,    68,    53,    69,
      70,    71,    72,    97,     0,     0,     0,     0,     0,     0,
      73,    74,    75,    76,    48,     0,     0,    49,     0,     0,
      50,     0,     0,    51,     0,     0,    52,     0,     0,    53
};

static const yytype_int8 yycheck[] =
{
       3,     3,     4,     3,     4,     6,    12,     9,     5,     9,
      11,     3,     4,     3,     4,    18,    19,    20,     3,     4,
      55,    56,     6,     7,    13,    14,    15,    16,    17,    18,
      19,    20,    21,    22,     6,    45,    46,    47,    48,    11,
       6,     7,    44,     8,    44,     3,     4,    49,     0,    49,
      10,    54,    44,     6,     7,     6,     7,    49,     5,    49,
      45,    46,    47,    48,    99,    10,    55,     6,     7,    17,
      20,    47,    18,    32,    77,    78,    79,    80,    81,    57,
      -1,    84,    23,    24,    25,    26,    27,    28,    29,    30,
      31,    32,    33,    34,    35,    36,    37,    38,    39,    40,
      41,    42,    43,    82,    -1,    -1,    -1,    -1,    -1,    -1,
      51,    52,    53,    54,    24,    -1,    -1,    27,    -1,    -1,
      30,    -1,    -1,    33,    -1,    -1,    36,    -1,    -1,    39
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    12,    57,     8,     0,     3,     4,    45,    46,    47,
      48,    58,    59,    60,    61,    62,    74,     6,     7,     5,
       6,     7,    10,    59,    61,    74,    62,    44,    49,    63,
      64,    65,    74,    13,    14,    15,    16,    17,    18,    19,
      20,    21,    22,    55,    71,    72,    73,     7,    24,    27,
      30,    33,    36,    39,    70,     6,     7,    10,    23,    25,
      26,    28,    29,    31,    32,    34,    35,    37,    38,    40,
      41,    42,    43,    51,    52,    53,    54,    66,    67,    68,
      69,    70,     6,    11,     5,    63,    74,    64,     9,    64,
      71,    74,    74,    74,    49,    74,    74,    72,    74,     7,
      11,     9
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    56,    57,    57,    58,    58,    59,    60,    60,    60,
      60,    61,    61,    62,    62,    63,    63,    63,    64,    64,
      65,    65,    65,    65,    65,    65,    65,    65,    66,    66,
      66,    66,    67,    67,    67,    67,    68,    68,    68,    68,
      68,    69,    69,    69,    69,    69,    69,    70,    70,    70,
      70,    70,    70,    71,    71,    72,    73,    73,    73,    73,
      73,    73,    73,    73,    73,    73,    73,    74,    74
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     9,     7,     1,     3,     3,     1,     1,     1,
       1,     1,     3,     1,     4,     1,     3,     3,     4,     1,
       1,     3,     3,     3,     3,     3,     3,     3,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     3,     3,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YYPARSE_PARAM, YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value, YYPARSE_PARAM); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, void *YYPARSE_PARAM)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  YY_USE (YYPARSE_PARAM);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, void *YYPARSE_PARAM)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep, YYPARSE_PARAM);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule, void *YYPARSE_PARAM)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)], YYPARSE_PARAM);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, YYPARSE_PARAM); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep, void *YYPARSE_PARAM)
{
  YY_USE (yyvaluep);
  YY_USE (YYPARSE_PARAM);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void *YYPARSE_PARAM)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 2: /* msc: TOK_MSC TOK_OCBRACKET optlist TOK_SEMICOLON entitylist TOK_SEMICOLON arclist TOK_SEMICOLON TOK_CCBRACKET  */
#line 291 "mscgen_language.y"
{
    (yyval.msc) = MscAlloc((yyvsp[-6].opt), (yyvsp[-4].entitylist), (yyvsp[-2].arclist));
    *(Msc *)yyparse_result = (yyval.msc);

}
#line 1450 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 3: /* msc: TOK_MSC TOK_OCBRACKET entitylist TOK_SEMICOLON arclist TOK_SEMICOLON TOK_CCBRACKET  */
#line 297 "mscgen_language.y"
{
    (yyval.msc) = MscAlloc(NULL, (yyvsp[-4].entitylist), (yyvsp[-2].arclist));
    *(Msc *)yyparse_result = (yyval.msc);

}
#line 1460 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 5: /* optlist: optlist TOK_COMMA opt  */
#line 305 "mscgen_language.y"
{
    (yyval.opt) = MscLinkOpt((yyvsp[-2].opt), (yyvsp[0].opt));
}
#line 1468 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 6: /* opt: optval TOK_EQUAL string  */
#line 310 "mscgen_language.y"
{
    (yyval.opt) = MscAllocOpt((yyvsp[-2].optType), (yyvsp[0].string));
}
#line 1476 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 11: /* entitylist: entity  */
#line 317 "mscgen_language.y"
{
    (yyval.entitylist) = MscLinkEntity(NULL, (yyvsp[0].entity));   /* Create new list */
}
#line 1484 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 12: /* entitylist: entitylist TOK_COMMA entity  */
#line 321 "mscgen_language.y"
{
    (yyval.entitylist) = MscLinkEntity((yyvsp[-2].entitylist), (yyvsp[0].entity));     /* Add to existing list */
}
#line 1492 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 13: /* entity: string  */
#line 328 "mscgen_language.y"
{
    (yyval.entity) = MscAllocEntity((yyvsp[0].string));
}
#line 1500 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 14: /* entity: entity TOK_OSBRACKET attrlist TOK_CSBRACKET  */
#line 332 "mscgen_language.y"
{
    MscEntityLinkAttrib((yyvsp[-3].entity), (yyvsp[-1].attrib));
}
#line 1508 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 15: /* arclist: arc  */
#line 338 "mscgen_language.y"
{
    (yyval.arclist) = MscLinkArc(NULL, (yyvsp[0].arc));      /* Create new list */
}
#line 1516 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 16: /* arclist: arclist TOK_SEMICOLON arc  */
#line 342 "mscgen_language.y"
{
    (yyval.arclist) = MscLinkArc((yyvsp[-2].arclist), (yyvsp[0].arc));     /* Add to existing list */
}
#line 1524 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 17: /* arclist: arclist TOK_COMMA arc  */
#line 346 "mscgen_language.y"
{
    /* Add a special 'parallel' arc */
    (yyval.arclist) = MscLinkArc(MscLinkArc((yyvsp[-2].arclist), MscAllocArc(NULL, NULL, MSC_ARC_PARALLEL, lex_getlinenum())), (yyvsp[0].arc));
}
#line 1533 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 18: /* arc: arcrel TOK_OSBRACKET attrlist TOK_CSBRACKET  */
#line 355 "mscgen_language.y"
{
    MscArcLinkAttrib((yyvsp[-3].arc), (yyvsp[-1].attrib));
}
#line 1541 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 20: /* arcrel: TOK_SPECIAL_ARC  */
#line 361 "mscgen_language.y"
{
    (yyval.arc) = MscAllocArc(NULL, NULL, (yyvsp[0].arctype), lex_getlinenum());
}
#line 1549 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 21: /* arcrel: string relation_box string  */
#line 365 "mscgen_language.y"
{
    (yyval.arc) = MscAllocArc((yyvsp[-2].string), (yyvsp[0].string), (yyvsp[-1].arctype), lex_getlinenum());
}
#line 1557 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 22: /* arcrel: string relation_bi string  */
#line 369 "mscgen_language.y"
{
    MscArc arc = MscAllocArc((yyvsp[-2].string), (yyvsp[0].string), (yyvsp[-1].arctype), lex_getlinenum());
    MscArcLinkAttrib(arc, MscAllocAttrib(MSC_ATTR_BI_ARROWS, strdup_s("true")));
    (yyval.arc) = arc;
}
#line 1567 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 23: /* arcrel: string relation_to string  */
#line 375 "mscgen_language.y"
{
    (yyval.arc) = MscAllocArc((yyvsp[-2].string), (yyvsp[0].string), (yyvsp[-1].arctype), lex_getlinenum());
}
#line 1575 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 24: /* arcrel: string relation_line string  */
#line 379 "mscgen_language.y"
{
    MscArc arc = MscAllocArc((yyvsp[-2].string), (yyvsp[0].string), (yyvsp[-1].arctype), lex_getlinenum());
    MscArcLinkAttrib(arc, MscAllocAttrib(MSC_ATTR_NO_ARROWS, strdup_s("true")));
    (yyval.arc) = arc;
}
#line 1585 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 25: /* arcrel: string relation_from string  */
#line 385 "mscgen_language.y"
{
    (yyval.arc) = MscAllocArc((yyvsp[0].string), (yyvsp[-2].string), (yyvsp[-1].arctype), lex_getlinenum());
}
#line 1593 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 26: /* arcrel: string relation_to TOK_ASTERISK  */
#line 389 "mscgen_language.y"
{
    (yyval.arc) = MscAllocArc((yyvsp[-2].string), strdup_s("*"), (yyvsp[-1].arctype), lex_getlinenum());
}
#line 1601 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 27: /* arcrel: TOK_ASTERISK relation_from string  */
#line 393 "mscgen_language.y"
{
    (yyval.arc) = MscAllocArc((yyvsp[0].string), strdup_s("*"), (yyvsp[-1].arctype), lex_getlinenum());
}
#line 1609 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 54: /* attrlist: attrlist TOK_COMMA attr  */
#line 405 "mscgen_language.y"
{
    (yyval.attrib) = MscLinkAttrib((yyvsp[-2].attrib), (yyvsp[0].attrib));
}
#line 1617 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 55: /* attr: attrval TOK_EQUAL string  */
#line 410 "mscgen_language.y"
{
    (yyval.attrib) = MscAllocAttrib((yyvsp[-2].attribType), (yyvsp[0].string));
}
#line 1625 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 67: /* string: TOK_QSTRING  */
#line 421 "mscgen_language.y"
{
    (yyval.string) = removeEscapes((yyvsp[0].string));
}
#line 1633 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;

  case 68: /* string: TOK_STRING  */
#line 425 "mscgen_language.y"
{
    (yyval.string) = (yyvsp[0].string);
}
#line 1641 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"
    break;


#line 1645 "/home/vsc/github/doxygen/Debug/generated_src/mscgen_language.cpp"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (YYPARSE_PARAM, YY_("syntax error"));
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval, YYPARSE_PARAM);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp, YYPARSE_PARAM);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YYPARSE_PARAM, YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, YYPARSE_PARAM);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp, YYPARSE_PARAM);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

#line 428 "mscgen_language.y"



/* END OF FILE */
