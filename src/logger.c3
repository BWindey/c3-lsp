module c3_lsp;

import std::io::file;
import std::time::datetime;

File log_file;

macro void? initialize_log_file(String[] args) {
	String prog_path = args[0];
	bool clean = false;
	if (args.len >= 2 && args[1] == "--clean") {
		clean = true;
	}

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

macro void log(String message) {
	if (catch error = _log(message)) {
		io::fprintfn(
			io::stderr(),
			"Failed to log the following message: %s\nReason: %s\n",
			message,
			error
		)!!;
	}
}
