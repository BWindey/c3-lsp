// This file will take in input from the main function and handle it accordingly
module c3_lsp;

import std::core::dstring;
import std::core::string;
import std::io;

<*
	@require @typekind(message) == STRUCT : `Can only send structs`
*>
macro void send_message(message) {
	String serialized_message = string::tformat("%s", message);
	io::printfn(
		"Content-Length: %d\r\n\r\n%s",
		serialized_message.len, serialized_message
	);
}

fn void send_error(String request_id, ErrorCode code, String message_format, args...) {
	String formatted_msg = string::tformat(message_format, args);
	send_message((ResponseMessage) {
		.requestID = "",
		.result = null,
		.error = &&(ResponseError) {
			.code = code.ordinal,
			.message = formatted_msg,
		}
	});
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
	String extracted_method = extract_method(body, &buffer)!;
}
