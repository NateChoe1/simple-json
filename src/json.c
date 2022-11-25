#include <stdlib.h>

#include <simple-json/json.h>

char *json_strerror(int code) {
	switch (code) {
	case JSON_SUCCESS:	return "Success";
	case JSON_ALLOC_FAIL:	return "Failed to allocate memory";
	case JSON_SYNTAX_ERROR:	return "Syntax error";
	default:		return "Unknown error code";
	}
}

void json_free(union json_value *value) {
	int i;
	switch (value->type) {
	case JSON_OBJECT:
		for (i = 0; i < value->object.size; ++i) {
			json_free(value->object.keys + i);
			json_free(value->object.values + i);
		}
		free(value->object.keys);
		free(value->object.values);
		break;
	case JSON_ARRAY:
		for (i = 0; i < value->array.size; ++i) {
			json_free(value->array.data + i);
		}
		free(value->array.data);
		break;
	case JSON_STRING:
		free(value->string.data);
		break;
	case JSON_NUMBER: case JSON_BOOL: case JSON_NULL:
		break;
	}
}
