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

fn void test_decode_message_failure_mismatch() @test {
	String _message = "Content-Length: 11\r\n\r\n{\"hello\": 3}";
	DString message = dstring::temp_with_capacity(_message.len);
	message.append(_message);
	String? decoded_body_opt = decode_message(&message);
	assert(!@ok(decoded_body_opt));
	assert(@catch(decoded_body_opt) == LENGTH_MISMATCH);
	assert(message.len() == 0);
}

fn void test_decode_message_failure_invalid_header() @test {
	String _message = "Some-giberish: haai\r\n\r\n{\"hello\": 3}";
	DString message = dstring::temp_with_capacity(_message.len);
	message.append(_message);
	String? decoded_body_opt = decode_message(&message);
	assert(!@ok(decoded_body_opt));
	assert(@catch(decoded_body_opt) == INVALID_HEADER);
	assert(message.len() == 0);
}

fn void test_decode_message_failure_incomplete() @test {
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
