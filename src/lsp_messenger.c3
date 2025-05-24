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

faultdef MESSAGE_INCOMPLETE, INVALID_HEADER, LENGTH_MISMATCH;

fn void send_message(String message) {
	io::printfn("Content-Length: %d\r\n\r\n%s", message.len, message);
}

fn void send_error(String request_id, ErrorCode code, String message_format, args...) {
	String formatted_msg = string::tformat(message_format, args);
	String formatted_payload = string::tformat(
		`{"id":"%s","error":{"code":%s,"mesage":"%s"}}`,
		request_id, code, formatted_msg
	);
	send_message(formatted_payload);
}

fn void? handle_incoming(String message) @maydiscard {
	// Initialize once
	static DString buffer;
	if (!buffer) {
		buffer.tinit(capacity: 1024);
	}

	buffer.append(message);

	// Rethrow but actually discard, not superclean, but should work.
	String body = decode_message(&buffer)!;
}

fn String? decode_message(DString* buffer) {
	// Header, content
	String[] pieces = buffer.str_view().tsplit("\r\n\r\n");

	// We expect 1 or 2 header fields, an empty string and the body
	if (pieces.len < 2) {
		return MESSAGE_INCOMPLETE?;
	}

	usz content_length;
	if (pieces[0].starts_with("Content-Length:")) {
		content_length = parse_content_length(pieces[0], buffer)!;
	} else {
		send_error(
			"", INVALID_REQUEST,
			"Invalid header: %s", pieces[0]
		);
		buffer.clear();
		return INVALID_HEADER?;
	}

	String content = pieces[1];
	if (content_length != content.len) {
		send_error(
			"", ErrorCode.PARSE_ERROR,
			"Content-Length from header does not match actual length. "
			"In header: %d. Actual: %d",
			content_length, content
		);
		buffer.clear();
		return LENGTH_MISMATCH?;
	}
	return content;
}

fn usz? parse_content_length(String header, DString* buffer) {
	String stripped_header = header.strip("Content-Length:").trim();
	usz? content_length = stripped_header.to_integer(usz);
	if (catch error = content_length) {
		send_error(
			"", ErrorCode.PARSE_ERROR,
			"Error parsing 'Content-Length' header: %s", error
		);
		buffer.clear();
		return error?;
	}
	return content_length;
}
