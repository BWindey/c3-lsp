// Copyright (c) 2021-2022 Christoffer Lerno. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.
// Slightly modified by BWindey, and availablue under same MIT license
// as actual C3 standard library
module custom;

// We still import actual io to get stdin and the errors.
import std::io;

<*
 Read from a stream (default is stdin) to the next "\n"
 or to the end of the stream, whatever comes first.
 "\n" and "\r" are included in the String.

 @param stream : `The stream to read from.`
 @require io::@is_instream(stream) : `The stream must implement InStream.`
 @param [inout] allocator : `the allocator to use.`
 @return `The string containing the data read.`
*>
macro String? readline(Allocator allocator, stream = io::stdin())
{
	bool $is_stream = @typeis(stream, InStream);
	$if $is_stream:
		$typeof(&stream.read_byte) func = &stream.read_byte;
		char val = func((void*)stream)!;
	$else
		char val = stream.read_byte()!;
	$endif

	if (val == '\n') return "\n";
	@pool()
	{
		DString str = dstring::temp_with_capacity(256);
		str.append(val);
		while (1)
		{
			$if $is_stream:
				char? c = func((void*)stream);
			$else
				char? c = stream.read_byte();
			$endif
			if (catch err = c)
			{
				if (err == io::EOF) break;
				return err?;
			}
			str.append_char(c);
			if (c == '\n') break;
		}
		return str.copy_str(allocator);
	};
}

<*
 Reads a string, see `readline`, except the it is allocated
 on the temporary allocator and does not need to be freed.

 @param stream : `The stream to read from.`
 @require io::@is_instream(stream) : `The stream must implement InStream.`
 @return `The temporary string containing the data read.`
*>
macro String? treadline(stream = io::stdin())
{
	return readline(tmem, stream) @inline;
}
