import std.stdio : writeln,writefln;
import event     : Events;


void
main () {
    auto events = Events!AppEvent ();
    // APP_START
    events ~= AppEvent (AppEvent.Type.START);

	foreach (ref event; events)
		writeln (event);
}

struct
AppEvent {
    Type type;

    enum 
    Type : ushort {
        _                   = 0,     
        APP                 = 2^^14,  // 16384
        START               = APP + 1,
        DRAW                = APP + 2,
    }
}
