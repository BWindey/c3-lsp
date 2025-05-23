module c3_lsp;

import std::io;
import std::core::mem;
import std::io::file;
import std::time::datetime;

/*
	Return-codes:
	- 0: OK
	- 1x: failed opening files/buffers/setup
	- 2x: failed to read
	- 3x: failure while closing up
*/

File log_file;

macro void? initialize_log_file(String prog_path) {
	log_file = file::open("c3_lsp.log", "w")!;
	log_file.write("C3-lsp is starting up.\n")!;
	log_file.write("It currently is ")!;
	log_file.write(datetime::tformat(DateTimeFormat.DATETIME, datetime::now().to_local()))!;
	log_file.write("\nWe're alive from: ")!;
	log_file.write(prog_path)!;
	log_file.write("\n")!;
}

macro void? close_log_file() {
	_log("Shutting down LSP.")!;
	log_file.close()!;
}

macro void? _log(String message) {
	log_file.write("[C3-lsp, ")!;
	log_file.write(datetime::tformat(DateTimeFormat.DATETIME, datetime::now().to_local()))!;
	log_file.write("] ")!;
	log_file.write(message)!;
	log_file.write("\n")!;
}

macro log(String message) {
	if (catch error = _log(message)) {
		io::fprintfn(
			io::stderr(),
			"Failed to log the following message: %s\nReason: %s\n",
			message,
			error
		);
	}
}

fn int main(String[] args) {
	if (catch error = initialize_log_file(args[0])) {
		io::fprintf(io::stderr(), "Failed to initialize log-file 'c3_lsp.log': %s\n", error)!!;
		return 10;
	}

	while (true) {
		String? input = io::treadline();
		if (catch error = input) {
			if (error == io::EOF) {
				break;
			}
			io::fprintf(io::stderr(), "Failed to read from stdin: %s", error)!!;
			return 20;
		}

		log(input);
	}

	if (catch error = close_log_file()) {
		io::fprintf(io::stderr(), "Failed to close log-file 'c3_lsp.log': %s\n", error)!!;
		return 30;
	}
	return 0;
}
