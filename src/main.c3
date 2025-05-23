module c3_lsp;

import std::io;
import std::os;

/*
	Return-codes:
	- 0: OK
	- 1x: failed opening files/buffers/setup
	- 2x: failed to read
	- 3x: failure while closing up
*/

macro error_exit(int code, String message_format, args...) {
	io::fprintf(io::stderr(), message_format, args)!!;
	os::exit(code);
}

fn int main(String[] args) {
	if (catch error = initialize_log_file(args)) {
		error_exit(10, "Failed to initialize log-file 'c3_lsp.log': %s\n", error);
	}

	while (true) {
		String? input = io::treadline();
		if (catch error = input) {
			if (error == io::EOF) {
				break;
			}
			error_exit(20, "Failed to read from stdin: %s\n", error);
		}
		// TODO: handle this input
		log(input);
	}

	if (catch error = close_log_file()) {
		error_exit(30, "Failed to close log-file 'c3_lsp.log': %s\n", error);
	}
	return 0;
}
