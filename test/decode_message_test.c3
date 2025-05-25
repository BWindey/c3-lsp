module c3_lsp;

import std::io;

fn void test_decode_message_success() @test {
	String _message = "Content-Length: 12\r\n\r\n{\"hello\": 3}";
	DString message = dstring::temp_with_capacity(_message.len);
	message.append(_message);
	String? decoded_body_opt = decode_message(&message);
	assert(@ok(decoded_body_opt));
	if (try decoded_body = decoded_body_opt) {
		assert(decoded_body == "{\"hello\": 3}");
	}
	assert(message.len() > 0);
}

fn void test_decode_message_failure__mismatch() @test {
	String _message = "Content-Length: 11\r\n\r\n{\"hello\": 3}";
	DString message = dstring::temp_with_capacity(_message.len);
	message.append(_message);
	String? decoded_body_opt = decode_message(&message);
	assert(!@ok(decoded_body_opt));
	assert(@catch(decoded_body_opt) == LENGTH_MISMATCH);
	assert(message.len() == 0);
}

fn void test_decode_message_failure__invalid_header() @test {
	String _message = "Some-giberish: haai\r\n\r\n{\"hello\": 3}";
	DString message = dstring::temp_with_capacity(_message.len);
	message.append(_message);
	String? decoded_body_opt = decode_message(&message);
	assert(!@ok(decoded_body_opt));
	assert(@catch(decoded_body_opt) == INVALID_HEADER);
	assert(message.len() == 0);
}

fn void test_decode_message_failure__incomplete() @test {
	String _message = "Content-Length: 11\r\n";
	DString message = dstring::temp_with_capacity(_message.len);
	message.append(_message);
	String? decoded_body_opt = decode_message(&message);
	assert(!@ok(decoded_body_opt));
	assert(@catch(decoded_body_opt) == MESSAGE_INCOMPLETE);
	assert(message.len() > 0);
}

fn void test_parse_content_length_success() @test {
	String _header = "Content-Length: 11\r\n";
	DString header = dstring::temp_with_capacity(_header.len);
	header.append(_header);
	usz? content_length_opt = parse_content_length(_header, &header);
	assert(@ok(content_length_opt));
	if (try content_length = content_length_opt) {
		assert(content_length == 11);
	}
	assert(header.len() > 0);
}

fn void test_parse_content_length_failure() @test {
	String _header = "Content-Length: 1x\r\n";
	DString header = dstring::temp_with_capacity(_header.len);
	header.append(_header);
	usz? content_length_opt = parse_content_length(_header, &header);
	assert(!@ok(content_length_opt));
	assert(@catch(content_length_opt) == string::MALFORMED_INTEGER);
	assert(header.len() == 0);
}

fn void extract_method_success() @test {
	String _buffer_start = "Content-Length: 1x\r\n\r\n";
	String body = `{"id": "123", "method": "textDocument/changed", "tada": 0}`;
	DString buffer = dstring::temp_with_capacity(_buffer_start.len + body.len);
	buffer.append(_buffer_start);
	buffer.append(body);

	String? parsed_method_opt = extract_method(body, &buffer);
	assert(@ok(parsed_method_opt));
	if (try parsed_method = parsed_method_opt) {
		assert(
			parsed_method == "textDocument/changed",
			"\nExpected: %s\nGot: %s\n", "textDocument/changed", parsed_method
		);
	}
	assert(buffer.len() > 0);
}

fn void extract_method_failure__method_not_found() @test {
	String _buffer_start = "Content-Length: 1x\r\n\r\n";
	String body = `{"id": "123", "tada": 0}`;
	DString buffer = dstring::temp_with_capacity(_buffer_start.len + body.len);
	buffer.append(_buffer_start);

	String? parsed_method_opt = extract_method(body, &buffer);
	assert(!@ok(parsed_method_opt));
	assert(@catch(parsed_method_opt) == NOT_FOUND);
	assert(buffer.len() == 0);
}

fn void extract_method_failure__value_not_found() @test {
	String _buffer_start = "Content-Length: 1x\r\n\r\n";
	String body = `{"id": "123", "method": 3}`;
	DString buffer = dstring::temp_with_capacity(_buffer_start.len + body.len);
	buffer.append(_buffer_start);

	String? parsed_method_opt = extract_method(body, &buffer);
	assert(!@ok(parsed_method_opt));
	assert(@catch(parsed_method_opt) == VALUE_NOT_FOUND);
	assert(buffer.len() == 0);
}

fn void extract_method_failure__end_of_value_not_found() @test {
	String _buffer_start = "Content-Length: 1x\r\n\r\n";
	String body = `{"id": "123", "method": "imcomplete}`;
	DString buffer = dstring::temp_with_capacity(_buffer_start.len + body.len);
	buffer.append(_buffer_start);

	String? parsed_method_opt = extract_method(body, &buffer);
	assert(!@ok(parsed_method_opt));
	assert(@catch(parsed_method_opt) == NOT_FOUND);
	assert(buffer.len() == 0);
}

