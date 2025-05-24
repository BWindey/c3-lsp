// This file will take in input from the main function and handle it accordingly
module c3_lsp;

import std::core::dstring;
import std::core::string;
import std::io;

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

fn void send_error(String request_id, ErrorCode code, String message_format, args...) {
	String formatted_msg = string::tformat(message_format, args);

	io::printfn(
		`{"id":"%s","error":{"code":%s,"mesage":"%s"}}`,
		request_id, code, formatted_msg
	);
}

fn void? handle_incoming(String message) @maydiscard {
	// Initialize once
	static DString buffer;
	if (!buffer) {
		buffer.tinit(capacity: 1024);
	}

	buffer.append(message);

	String[] pieces = buffer.str_view().tsplit("\r\n");

	// We expect 1 or 2 header fields, an empty string and the body
	if (pieces.len <= 2) {
		return;
	}
	bool found_content_length_header = false;
	bool found_content_type_header = false;

	usz content_length;
	// Content-type has a default value.
	// We will be completely ignoring the content-type though, as other types
	// are not yet in spec...
	String content_type = "application/vscode-jsonrpc; charset=utf-8";

	for (int i = 0; i< pieces.len && pieces[i] != ""; i++) {
		switch {
			case pieces[i].starts_with("Content-Length"):
				content_length = parse_content_length(pieces[i], &buffer)!;
				found_content_length_header = true;
			case pieces[i].starts_with("Content-Type"):
				content_type = pieces[i].strip("Content-Type:").trim();
				found_content_type_header = true;
			default:
				send_error(
					"", INVALID_REQUEST,
					"Invalid header: %s\n", pieces[i]
				);
				buffer.clear();
				return;
		}
	}
	if (!found_content_length_header) {
		send_error(
			"", ErrorCode.INVALID_REQUEST,
			"Could not find required 'Content-Length' header."
		);
		buffer.clear();
		return;
	}
}

fn usz? parse_content_length(String header, DString* buffer) {
	String stripped_header = header.strip("Content-Length:").trim();
	usz? content_length = stripped_header.to_integer(usz);
	if (catch error = content_length) {
		send_error(
			"", ErrorCode.PARSE_ERROR,
			"Error parsing 'Content-Length' header: %s\n", error
		);
		buffer.clear();
		return error?;
	}
	return content_length;
}
