%{
/*
 * Copyright (C) 2009 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <string.h>
#include "fsmparse.h"

#define MAX_LENGTH 1024
int gLine = 1;
int gColumn = 1;
int gPos = 0;
char string_buffer[MAX_LENGTH];
char* string_pos;

#define ADVANCE do {yylloc.first_column=gPos; yylloc.last_column=gPos+yyleng; \
                    gColumn+=yyleng; gPos+=yyleng;} while(0)

%}

%x STR

%option noyywrap

%%

\" {
    BEGIN(STR);
    string_pos = string_buffer;
    yylloc.first_column = gPos;
    ++gColumn;
    ++gPos;
}

<STR>{
  \" {
      ++gColumn;
      ++gPos;
      BEGIN(INITIAL);
      *string_pos = '\0';
      yylval.str = strdup(string_buffer);
      yylloc.last_column = gPos;
      return STRING;
  }

  \\n   { gColumn += yyleng; gPos += yyleng; *string_pos++ = '\n'; }
  \\t   { gColumn += yyleng; gPos += yyleng;  *string_pos++ = '\t'; }
  \\\"  { gColumn += yyleng; gPos += yyleng;  *string_pos++ = '\"'; }
  \\\\  { gColumn += yyleng; gPos += yyleng;  *string_pos++ = '\\'; }

  . {
      ++gColumn;
      ++gPos;
      *string_pos++ = yytext[0];
  }
}

digraph  ADVANCE; return DIGRAPH;
label  ADVANCE; return LABEL;
defer  ADVANCE; return DEFER;
rank  ADVANCE; return RANK;
dir  ADVANCE; return DIR;
node  ADVANCE; return NODE;
same  ADVANCE; return SAME;
->    ADVANCE; return RARROW;

[a-zA-Z0-9_:/.]+ {
  ADVANCE;
  yylval.str = strdup(yytext);
  return VAR;
}

[\[\]{}=;]        ADVANCE; return yytext[0];

[ \t]+            ADVANCE;

(#.*)?\n          gPos += yyleng; ++gLine; gColumn = 1;

.                 return BAD;
