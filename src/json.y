/*  simple-json, a simple json library
 *  Copyright (C) 2022  Nate Choe <nate@natechoe.dev>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

%{
#include <math.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <setjmp.h>

#include <simple-json/json.h>
#include <simple-json/consts.h>

void yyerror(char *str);
int yylex();

static int json_init_object(union json_value *object);
static int json_add_object(union json_value *object,
		union json_value *key, union json_value *value);
static int json_init_array(union json_value *array);
static int json_add_array(union json_value *array, union json_value *value);

static union json_value *read_value; /* Calling yyparse stores values here */

static jmp_buf error_buf;
static int json_errno;
/* On error, yyparse stores an error number into json_error and jumps to
   error_buf */

extern FILE *yyin;
%}

%start file

%token TOK_STRING
%token TOK_NUMBER
%token TOK_TRUE
%token TOK_FALSE
%token TOK_NULL

%union {
	union json_value v;
	double n;
}

%%

file:
	value		{ memcpy(read_value, &$<v>1, sizeof *read_value); }

value:
	object
|	array
|	string
|	num
|	bool
|	null

object:
	'{' object_items '}'	{ memcpy(&$<v>$, &$<v>2, sizeof($<v>$)); }
|	'{' '}' {
		if ((json_errno = json_init_object(&$<v>$)) != JSON_SUCCESS) {
			longjmp(error_buf, 0);
		}
	}
object_items:
	string ':' value {
		if ((json_errno = json_init_object(&$<v>$)) != JSON_SUCCESS) {
			longjmp(error_buf, 0);
		}
		if ((json_errno = json_add_object(&$<v>$, &$<v>1, &$<v>3))
				!= JSON_SUCCESS) {
			longjmp(error_buf, 0);
		}
	}
|	object_items ',' string ':' value {
		if ((json_errno = json_add_object(&$<v>$, &$<v>3, &$<v>5))
				!= JSON_SUCCESS) {
			longjmp(error_buf, 0);
		}
	}

array:
	'[' array_items ']'	{ memcpy(&$<v>$, &$<v>2, sizeof($<v>$)); }
|	'[' ']' {
		if ((json_errno = json_init_array(&$<v>$)) != JSON_SUCCESS) {
			longjmp(error_buf, 0);
		}
	}
array_items:
	value {
		if ((json_errno = json_init_array(&$<v>$)) != JSON_SUCCESS) {
			longjmp(error_buf, 0);
		}
		if ((json_errno = json_add_array(&$<v>$, &$<v>1))
				!= JSON_SUCCESS) {
			longjmp(error_buf, 0);
		}
	}
|	array_items ',' value {
		if ((json_errno = json_add_array(&$<v>$, &$<v>3))
				!= JSON_SUCCESS) {
			longjmp(error_buf, 0);
		}
	}

string:
	TOK_STRING	{ memcpy(&$<v>$, &$<v>1, sizeof($<v>$)); }

num:
	TOK_NUMBER	{ $<v>$.type = JSON_NUMBER; $<v>$.number.value = $<n>1; }

bool:
	TOK_TRUE	{ $<v>$.type = JSON_BOOL; $<v>$.bool.truth = 1; }
|	TOK_FALSE	{ $<v>$.type = JSON_BOOL; $<v>$.bool.truth = 0; }

null:
	TOK_NULL	{ $<v>$.type = JSON_NULL; }

%%

void yyerror(char *str) {
	json_errno = JSON_SYNTAX_ERROR;
}
/* TODO: Implement this function properly */

static int json_init_object(union json_value *value) {
	value->type = JSON_OBJECT;
	value->object.size = 0;
	value->object.alloc = INITIAL_ALLOC;
	value->object.keys = malloc(value->object.alloc *
			sizeof *value->object.keys);
	if (value->object.keys == NULL) {
		goto error1;
	}
	value->object.values = malloc(value->object.alloc *
			sizeof *value->object.values);
	if (value->object.values == NULL) {
		goto error2;
	}
	return JSON_SUCCESS;
error2:
	free(value->object.keys);
error1:
	return JSON_ALLOC_FAIL;
}

static int json_add_object(union json_value *object,
		union json_value *key, union json_value *value) {
	if (object->object.size >= object->object.alloc) {
		size_t newalloc;
		union json_value *newkeys, *newvalues;
		newalloc = object->object.alloc * 2;
		newkeys = realloc(object->object.keys,
				newalloc * sizeof *newkeys);
		if (newkeys == NULL) {
			return JSON_ALLOC_FAIL;
		}
		object->object.keys = newkeys;
		newvalues = realloc(object->object.values,
				newalloc * sizeof *newvalues);
		if (newvalues == NULL) {
			return JSON_ALLOC_FAIL;
		}
		object->object.values = newvalues;
		object->object.alloc = newalloc;
	}
	memcpy(object->object.keys + object->object.size, key, sizeof *key);
	memcpy(object->object.values + object->object.size, value,
			sizeof *value);
	++object->object.size;
	return JSON_SUCCESS;
}

static int json_init_array(union json_value *array) {
	array->type = JSON_ARRAY;
	array->array.size = 0;
	array->array.alloc = INITIAL_ALLOC;
	array->array.data = malloc(array->array.alloc *
			sizeof *array->array.data);
	if (array->array.data == NULL) {
		return JSON_ALLOC_FAIL;
	}
	return JSON_SUCCESS;
	/* I hate the ternary operator with a flaming passion */
}

static int json_add_array(union json_value *array, union json_value *value) {
	if (array->array.size >= array->array.alloc) {
		union json_value *newdata;
		size_t newalloc;
		newalloc = array->array.alloc * 2;
		newdata = realloc(array->array.data, newalloc *
				sizeof *array->array.data);
		if (newdata == NULL)
			return JSON_ALLOC_FAIL;

		array->array.data = newdata;
		array->array.alloc = newalloc;
	}
	memcpy(array->array.data + (array->array.size++), value, sizeof *value);
	return JSON_SUCCESS;
}

int json_read(FILE *file, union json_value *ret) {
	yyin = file;
	read_value = ret;

	if (setjmp(error_buf)) {
		return json_errno;
	}

	yyparse();

	return JSON_SUCCESS;
}
