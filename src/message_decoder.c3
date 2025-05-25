module c3_lsp;

import std::core::string;
import std::core::dstring;

faultdef MESSAGE_INCOMPLETE, INVALID_HEADER, LENGTH_MISMATCH, VALUE_NOT_FOUND;

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

fn String? extract_method(String body, DString* buffer) {
	String to_search = `"method"`;
	usz? method_start = body.index_of(to_search);

	if (catch error = method_start) {
		send_error(
			"", ErrorCode.INVALID_REQUEST,
			`"method" key not found in request body`
		);
		buffer.clear();
		return error?;
	}

	method_start += to_search.len;

	String method_value_start = body[method_start..].trim_left(to_trim: " :");
	if (method_value_start.len <= 1 || method_value_start[0] != '"') {
		send_error(
			"", ErrorCode.PARSE_ERROR,
			`Could not find the value for key "method"`
		);
		buffer.clear();
		return VALUE_NOT_FOUND?;
	}

	usz? method_end = method_value_start[1..].index_of_char('"');
	if (catch error = method_end) {
		send_error(
			"", ErrorCode.INVALID_REQUEST,
			`Could not find end of value for key "method"`
		);
		buffer.clear();
		return error?;
	}

	return method_value_start[1..method_end];
}
