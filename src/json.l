%{
#include <stdio.h>
#include <stdlib.h>

#include <simple-json/json.h>
#include <simple-json/consts.h>

#include "json.tab.h"

static int json_strdecode(union json_value *ret, char *string, int len);
%}

CHAR		[^\\"]|\\[\\"/bnfrt]|\\u[0-9a-fA-F]{4}

%%

\"{CHAR}*\" {
	if (json_strdecode(&yylval.v, yytext, yyleng)) {
		return YYerror;
	}
	return TOK_STRING;
}
-?(0|[1-9][0-9]*)(\.[0-9]*)?([eE][+-]?[0-9]+)? {
	yylval.n = atof(yytext);
	return TOK_NUMBER;
}
true						{ return TOK_TRUE; }
false						{ return TOK_FALSE; }
null						{ return TOK_NULL; }
[ \n\r\t]					;
.						{ return yytext[0]; }

%%

static int json_strdecode(union json_value *ret, char *string, int len) {
/* Converts an encoded string to a json_value */
	int readind;

	if (string[0] != '"' || string[len - 1] != '"')
		return 1;

	ret->type = JSON_STRING;
	ret->string.len = 0;
	ret->string.alloc = INITIAL_ALLOC;
	ret->string.data = malloc(ret->string.alloc);
	if (ret->string.data == NULL) {
		return 1;
	}

	readind = 1;
	while (readind < len - 1) {
		char c;
		if (ret->string.len + 1 >= ret->string.alloc) {
			char *newdata;
			ret->string.alloc *= 2;
			newdata = realloc(ret->string.data, ret->string.alloc);
			if (newdata == NULL) {
				goto error;
			}
			ret->string.data = newdata;
		}
		switch (c = string[readind++]) {
		case '\"':
			goto error;
		case '\\':
			switch (string[readind++]) {
			case '\"': c = '\"'; goto normal;
			case '\\': c = '\\'; goto normal;
			case '/':  c = '/';  goto normal;
			case 'b':  c = '\b'; goto normal;
			case 'f':  c = '\f'; goto normal;
			case 'n':  c = '\n'; goto normal;
			case 'r':  c = '\r'; goto normal;
			case 't':  c = '\t'; goto normal;
			case 'u':
				goto unicode;
			default:
				goto error;
			}
			break;
		unicode:
			goto error;
			/* TODO: Properly handle unicode */
		default: normal:
			ret->string.data[ret->string.len++] = c;
			break;
		}
	}
	if (readind > len - 1) {
		goto error;
	}
	ret->string.data[ret->string.len] = '\0';
	return 0;
error:
	free(ret->string.data);
	return 1;
}

int yywrap() {
	return 1;
}
