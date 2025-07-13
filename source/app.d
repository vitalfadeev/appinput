import std.stdio : writeln,writefln;
import what;


void
main () {
	foreach (what; Whats ())
		writeln (what);
}

