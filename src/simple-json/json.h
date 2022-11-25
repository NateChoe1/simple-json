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

extern void json_free(union json_value *value);
/* NOTE: free(value) is NEVER RUN when json_free is called. */

#endif
