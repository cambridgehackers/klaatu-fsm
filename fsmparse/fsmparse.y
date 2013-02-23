%{
#include <stdio.h>
#include <fcntl.h>
#include <KeyedVector.h>
#include <SortedVector.h>
#include <String8.h>
#define YYDEBUG 1
#define YYERROR_VERBOSE 1
#define YYTOKEN_TABLE 1
#include "fsmparse.h"

using namespace android;
typedef SortedVector<String8> STRLIST;
typedef KeyedVector<String8, STRLIST *> ARCTYPE;

extern int gLine, gColumn, yy_flex_debug;
extern int yylex();
extern struct yy_buffer_state *yy_scan_bytes (const char *bytes, size_t len);

static STRLIST event_names;
static KeyedVector<String8, ARCTYPE *> transition;
static char *eventname, *direction, *firststate;
static int error_count = 0;

static void add_elements(String8 currentstate, String8 targetstate, char *aevents)
{
    int tindex = transition.indexOfKey(currentstate);
    if (tindex < 0)
        tindex = transition.add(currentstate, new ARCTYPE);
    ARCTYPE *pitem = transition.valueAt(tindex);
    if (transition.indexOfKey(targetstate) < 0)
        transition.add(targetstate, new ARCTYPE);
    char *events = strdup(aevents);
    while (events) {
        char *p = strchr(events, '\n');
        if (p)
            *p++ = 0;
        if (strcmp(events, "0") && event_names.indexOf(String8(events)) < 0)
            event_names.add(String8(events));
        int sindex = pitem->indexOfKey(String8(events));
        if (sindex < 0)
            sindex = pitem->add(String8(events), new STRLIST);
        pitem->valueAt(sindex)->add(targetstate);
        events = p;
    }
}

static void add_transition(String8 first, String8 second, char *adir, char *aevent)
{
    if (strlen(first.string()) > 7 && !strncmp(first.string(), "default", 7))
        first = String8("default");
    if(strcmp(adir, "back"))
        add_elements(first, second, aevent);
    if(!strcmp(adir, "both") || !strcmp(adir, "back"))
        add_elements(second, first, aevent);
}

static const char *get_sname(const char *arg_name)
{
    char *ret = (char *)malloc(strlen(arg_name) + 7);
    char *p = ret;
    sprintf(ret, "%s_STATE", arg_name);
    while (*p) {
        if (*p >= 'a' && *p <= 'z')
            *p += 'A' - 'a';
        p++;
    }
    return ret;
}

static void write_file(FILE *fout)
{
    fprintf(fout, "namespace android {\n"
        "#ifdef FSM_DEFINE_ENUMS\n"
        "enum { EVENT_NONE=1,\n    ");
    int index = 0;
    for (size_t i = 0; i < event_names.size(); ++i) {
        fprintf(fout, "%s, ", event_names[i].string());
        if (index++ > 1) {
            index = 0;
            fprintf(fout, "\n    ");
        }
    }
    fprintf(fout, "MAX_WIFI_EVENT};\n"
        "#endif\n"
        "enum { STATE_NONE=1,\n    ");
    index = 0;
    for (size_t i = 0; i < transition.size(); ++i) {
        fprintf(fout, "%s, ", get_sname(transition.keyAt(i).string()));
        if (index++ > 1) {
            index = 0;
            fprintf(fout, "\n    ");
        }
    }
    fprintf(fout, "STATE_MAX};\n"
        "extern const char *sMessageToString[MAX_WIFI_EVENT];\n"
        "#ifdef FSM_INITIALIZE_CODE\n"
        "const char *sMessageToString[MAX_WIFI_EVENT];\n"
        "STATE_TABLE_TYPE state_table[STATE_MAX];\n"
        "void initstates(void)\n{\n");
    for (size_t i = 0; i < transition.size(); ++i)
        if (transition.valueAt(i)->size()) {
            ARCTYPE *p = transition.valueAt(i);
            fprintf(fout, "    static STATE_TRANSITION TRA_%s[] = {", transition.keyAt(i).string());
            for (size_t j = 0; j < p->size(); ++j) {
                STRLIST *pstr = p->valueAt(j);
                for (size_t k = 0; k < pstr->size(); ++k)
                    fprintf(fout, "{%s,%s}, ", p->keyAt(j).string(), get_sname(pstr->itemAt(k).string()));
            }
            fprintf(fout, "{0,0} };\n");
        }
    fprintf(fout, "\n");
    for (size_t i = 0; i < transition.size(); ++i) {
        const char *cptr = transition.keyAt(i).string();
        fprintf(fout, "    state_table[%s].name = \"%s\";\n", get_sname(cptr), cptr);
        if (transition.valueAt(i)->size())
            fprintf(fout, "    state_table[%s].tran = TRA_%s;\n", get_sname(cptr), cptr);
    }
    for (size_t i = 0; i < event_names.size(); ++i)
        fprintf(fout, "    sMessageToString[%s] = \"%s\";\n", event_names[i].string(), event_names[i].string());
    fprintf(fout, "}\n\n"
        "#endif\n} /* namespace android */\n");
}

static void yyerror(const char* errmsg)
{
    if (!strlen(errmsg))
        errmsg = "syntax error";
    printf("Error: [%d:%d]: %s\n", gLine, gColumn, errmsg);
    error_count++;
}

%}

%locations

%union {
    char* str;
}

%token DIGRAPH LABEL DEFER RANK DIR NODE SAME RARROW BAD
%token <str> STRING VAR
%type <str> name
%error-verbose
%%

input:  DIGRAPH name '{' node_list '}' { } ;

node_list: node_item | node_list node_item ;

node_item:
    NODE '[' node_name_list_opt ']'
    | name { firststate = $1; direction = (char *)""; eventname = (char *)"0"; } name_after
    | '{' RANK '=' SAME ';' name_list '}'
;

node_name_list_opt: /* empty */ { } | node_name_list ;

node_name_list: node_name_element | node_name_list node_name_element ;

node_name_element: VAR '=' VAR ;

name_after:
    '[' label_list ']' ';'
    | RARROW name transition_list_opt
        { add_transition(String8(firststate), String8($2), direction, eventname); }
;

label_list: label_element | label_list label_element ;

label_element:
    DEFER '=' name { add_elements(String8(firststate), String8("DEFER"), $3) }
    | LABEL '=' name
    | VAR '=' name
;

transition_list_opt: /* empty */ { } | '[' transition_list ']' ;

transition_list: transition_item | transition_list transition_item ;

transition_item:
     LABEL '=' name { eventname = $3; }
     | DIR '=' VAR { direction = $3 }
     | VAR '=' name
;

name_list: name | name_list name ;

name: STRING | VAR ;

%%

int main(int argc, char** argv)
{
    //yy_flex_debug = 1;
    //yydebug = 1;
    if (argc != 4 || strcmp(argv[1], "-o")) {
        printf("fsmparse -o <output_filename> <input_filename>\n");
        return 1;
    }
    int filein = open(argv[3], O_RDONLY);
    if (!filein) {
        printf("fsmparse: File not found: %s\n", argv[3]);
        return 1;
    }
    int size = lseek(filein, 0, SEEK_END) + 1;
    char *buffer = (char *)malloc(size);
    lseek(filein, 0, SEEK_SET);
    size = read(filein, buffer, size);
    buffer[size] = '\0';
    close(filein);
    yy_scan_bytes(buffer, size);
    int error = yyparse();
    printf("parse result %d: %d errors\n", error, error_count);
    FILE* fout = fopen(argv[2], "w");
    if (!fout) {
        printf("fsmparse: Cannot open outputfile: %s\n", argv[2]);
        return 1;
    }
    write_file(fout);
    fclose(fout);
    return 0;
}
