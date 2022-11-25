/* TODO: Proper error handling */

%{
#include <math.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <simple-json/json.h>
#include <simple-json/consts.h>

void yyerror(char *str);
int yylex();

static int json_init_object(union json_value *object);
static int json_add_object(union json_value *object,
		union json_value *key, union json_value *value);
static int json_init_array(union json_value *array);
static int json_add_array(union json_value *array, union json_value *value);

static void json_print(union json_value *value);

int yydebug = 1;
%}

%start input

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

input:
	value		{ json_print(&$<v>1); }
|	input value	{ json_print(&$<v>2); }

value:
	object
|	array
|	string
|	num
|	bool
|	null

object:
	'{' object_items '}'	{ memcpy(&$<v>$, &$<v>2, sizeof($<v>$)); }
|	'{' '}'		{ json_init_object(&$<v>$); }
object_items:
	string ':' value	{
		json_init_object(&$<v>$);
		json_add_object(&$<v>$, &$<v>1, &$<v>3);
	}
|	object_items ',' string ':' value {
		if (json_add_object(&$<v>$, &$<v>3, &$<v>5)) {
			yyerror("Couldn't add to object");
		}
	}

array:
	'[' array_items ']'	{ memcpy(&$<v>$, &$<v>2, sizeof($<v>$)); }
|	'[' ']'		{ json_init_array(&$<v>$); }
array_items:
	value		{ json_init_array(&$<v>$); json_add_array(&$<v>$, &$<v>1); }
|	array_items ',' value	{ json_add_array(&$<v>$, &$<v>3); }

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
	fprintf(stderr, "%s\n", str);
	return;
}

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
	return 0;
error2:
	free(value->object.keys);
error1:
	return 1;
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
			return 1;
		}
		object->object.keys = newkeys;
		newvalues = realloc(object->object.values,
				newalloc * sizeof *newvalues);
		if (newvalues == NULL) {
			return 1;
		}
		object->object.values = newvalues;
		object->object.alloc = newalloc;
	}
	memcpy(object->object.keys + object->object.size, key, sizeof *key);
	memcpy(object->object.values + object->object.size, value,
			sizeof *value);
	++object->object.size;
	return 0;
}

static int json_init_array(union json_value *array) {
	array->type = JSON_ARRAY;
	array->array.size = 0;
	array->array.alloc = INITIAL_ALLOC;
	array->array.data = malloc(array->array.alloc *
			sizeof *array->array.data);
	return array->array.data == NULL;
}

static int json_add_array(union json_value *array, union json_value *value) {
	if (array->array.size >= array->array.alloc) {
		union json_value *newdata;
		size_t newalloc;
		newalloc = array->array.alloc * 2;
		newdata = realloc(array->array.data, newalloc *
				sizeof *array->array.data);
		if (newdata == NULL)
			return 1;

		array->array.data = newdata;
		array->array.alloc = newalloc;
	}
	memcpy(array->array.data + (array->array.size++), value, sizeof *value);
	return 0;
}

static void json_print(union json_value *value) {
	int i;
	switch (value->type) {
	case JSON_OBJECT:
		printf("{\n");
		for (i = 0; i < value->object.size; ++i) {
			if (i != 0)
				printf(",\n");
			json_print(value->object.keys + i);
			printf(":\n");
			json_print(value->object.values + i);
		}
		printf("}\n");
		break;
	case JSON_ARRAY:
		printf("[\n");
		for (i = 0; i < value->array.size; ++i) {
			if (i != 0)
				printf(",\n");
			json_print(value->array.data + i);
		}
		printf("]\n");
		break;
	case JSON_STRING:
		printf("\"%s\"\n", value->string.data);
		break;
	case JSON_NUMBER:
		printf("%f\n", value->number.value);
		break;
	case JSON_BOOL:
		if (value->bool.truth) {
			printf("true\n");
		}
		else {
			printf("false\n");
		}
		break;
	case JSON_NULL:
		printf("null\n");
		break;
	}
}

int main() {
	yyparse();
}
