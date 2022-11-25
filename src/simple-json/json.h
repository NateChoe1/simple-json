#ifndef JSON_HAVE_JSON
#define JSON_HAVE_JSON

#include <stdio.h>

enum json_type {
	JSON_OBJECT,
	JSON_ARRAY,
	JSON_STRING,
	JSON_NUMBER,
	JSON_BOOL,
	JSON_NULL
};

struct json_object {
	enum json_type type;	/* Always JSON_OBJECT */
	size_t size;
	size_t alloc;
	union json_value *keys;
	union json_value *values;
};

struct json_array {
	enum json_type type;	/* Always JSON_ARRAY */
	size_t size;
	size_t alloc;
	union json_value *data;
};

struct json_string {
	enum json_type type;	/* Always JSON_STRING */
	size_t len;
	size_t alloc;
	char *data;
};

struct json_number {
	enum json_type type;	/* Always JSON_NUMBER */
	double value;
};

struct json_bool {
	enum json_type type;
	int truth;
};

union json_value {
	enum json_type type;
	struct json_object object;
	struct json_array array;
	struct json_string string;
	struct json_number number;
	struct json_bool bool;
};

extern int json_read(FILE *file, union json_value *ret);
/* Returns error code on error */
extern char *json_strerror(int code);

#define JSON_SUCCESS 0
#define JSON_ALLOC_FAIL 1
#define JSON_SYNTAX_ERROR 2

#endif
