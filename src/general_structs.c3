module c3_lsp;

// This file contains the general-use structs.
// Optional fields will be pointers and can contain `null` as value, those should
// not be sent/interpreted.
// Optional fields will be below a '// --- Optional --- ' comment.

enum ErrorCode: int (inline int code_value) {
	PARSE_ERROR = -32700,
	INVALID_REQUEST = -32600,
	METHOD_NOT_FOUND = -32601,
	INVALID_PARAMS = -32602,
	INTERNAL_ERROR = -32603,
	SERVER_NOT_INITIALIZED = -32002,
	UNKNOWN_ERROR_CODE = -32001,
	REQUEST_FAILED = -32803,
	SERVER_CANCELLED = -32802,
	CONTENT_MODIFIED = -32801,
	REQUEST_CANCELLED = -32800,
}

// Some JSON-esque types
enum LSPType {
	LSP_OBJECT, LSP_ARRAY, STRING, INT, UINT, DOUBLE, BOOL, NULL
}

struct LSPArray {
	LSPAny[] values;
}

struct LSPObject {
	String key;
	LSPAny value;
}

struct LSPAny {
	LSPType type;
	union {
		LSPObject* object;
		LSPArray* array;
		String string;
		int integer;
		uint uinteger;
		double decimal;
		bool boolean;
	}
}

// LSP datastructures
struct ResponseError {
	int code;
	String message;
	// --- Optional ---
	LSPAny* data;
}

enum RequestParamsType {
	LSP_ARRAY, LSP_OBJECT, NULL
}

struct RequestMessage {
	String requestID;
	String method;
	RequestParamsType paramsType;
	union {
		LSPArray array;
		LSPObject object;
	}
}

struct ResponseMessage {
	String requestID;
	// --- Optional ---
	LSPAny* result;
	ResponseError* error;
}
