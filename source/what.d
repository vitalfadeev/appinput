import std.stdio : writefln;
import libinput_d;
import libinput_struct;
import appinput;


auto
Whats () {
    return _Whats (null);
}
struct
_Whats {
    // 2 source
    //  - app       -> ...
    //  - libinput  -> Event
    // read ALL app events
    // then read 1 libinput event
    import libinput_struct   : LibInput;
    import appinput : AppInput;
    import appinput : AppEvent = Event;
    LibInput libinput;
    AppInput appinput;
    Source  _source;
    //What     _front;

    // front
    // back
    // empty
    // popFront
    // popBack
    // opOpAssign (string op : "~")

    this (void* _) {
        _init ();
    }

    void
    _init () {
        // appinput empty
        // libinput empty
        // setup front
        libinput = LibInput (null);
        appinput = AppInput ();
        // APP_START
        appinput ~= AppEvent (AppEvent.Type.START);
    }

    bool
    empty () {
        if (!appinput.empty) {
            _source = Source.APP;
            return false;
        }

        if (!libinput.empty) {  // wait
            _source = Source.INPUT;
            return false;
        }

        return true;
    }

    What
    front () {
        // read all appinput
        // then one libinput
        final
        switch (_source) {
            case Source.APP   : return What (appinput.front);
            case Source.INPUT : return What (libinput.front);
        }
    }

    void
    popFront () {
        final
        switch (_source) {
            case Source.APP   : appinput.popFront (); break;
            case Source.INPUT : libinput.popFront (); break;
        }
    }

    void
    opOpAssign (string op : "~", What) (What what) {
        if (what.is_app)
            appinput ~= what._app;
        else
        if (what.is_input)
            libinput ~= what._input;
    }
}

enum
Source {
    APP,
    INPUT,
}

struct
What {
    // ushort
    // libinput_event*
    //   ushort
    //   void*
    Type                     type;
    union {
             appinput.Event _app;
      libinput_struct.Event _input;  // (event = libinput_get_event (li)) != null
    }

    this (Type type) {
        this.type = type;
    }

    this (appinput.Event event) {
        import std.conv : to;
        this.type = event.type.to!(ushort).to!(Type);
        this._app = event;
    }

    this (libinput_struct.Event event) {
        import std.conv : to;
        this.type   = event.type.to!(ushort).to!(Type);
        this._input = event;
    }

    //Type type () { return _event.type; }  // *(libinput_event* _event).type

    enum
    Type : ushort {
        NONE                    = LIBINPUT_EVENT_NONE,
        DEVICE_ADDED            = LIBINPUT_EVENT_DEVICE_ADDED,
        DEVICE_REMOVED          = LIBINPUT_EVENT_DEVICE_REMOVED,
        KEYBOARD_KEY            = LIBINPUT_EVENT_KEYBOARD_KEY,
        POINTER_MOTION          = LIBINPUT_EVENT_POINTER_MOTION,
        POINTER_MOTION_ABSOLUTE = LIBINPUT_EVENT_POINTER_MOTION_ABSOLUTE,
        POINTER_BUTTON          = LIBINPUT_EVENT_POINTER_BUTTON,
        POINTER_AXIS            = LIBINPUT_EVENT_POINTER_AXIS,
        TOUCH_DOWN              = LIBINPUT_EVENT_TOUCH_DOWN,
        TOUCH_UP                = LIBINPUT_EVENT_TOUCH_UP,
        TOUCH_MOTION            = LIBINPUT_EVENT_TOUCH_MOTION,
        TOUCH_CANCEL            = LIBINPUT_EVENT_TOUCH_CANCEL,
        TABLET_TOOL_AXIS        = LIBINPUT_EVENT_TABLET_TOOL_AXIS,
        TABLET_TOOL_PROXIMITY   = LIBINPUT_EVENT_TABLET_TOOL_PROXIMITY,
        TABLET_TOOL_TIP         = LIBINPUT_EVENT_TABLET_TOOL_TIP,
        TABLET_TOOL_BUTTON      = LIBINPUT_EVENT_TABLET_TOOL_BUTTON,
        GESTURE_SWIPE_BEGIN     = LIBINPUT_EVENT_GESTURE_SWIPE_BEGIN,
        GESTURE_SWIPE_UPDATE    = LIBINPUT_EVENT_GESTURE_SWIPE_UPDATE,
        GESTURE_SWIPE_END       = LIBINPUT_EVENT_GESTURE_SWIPE_END,
        GESTURE_PINCH_BEGIN     = LIBINPUT_EVENT_GESTURE_PINCH_BEGIN,
        GESTURE_PINCH_UPDATE    = LIBINPUT_EVENT_GESTURE_PINCH_UPDATE,
        GESTURE_PINCH_END       = LIBINPUT_EVENT_GESTURE_PINCH_END,
        _                       = NONE,  // 0
        APP                     = appinput.Event.Type.APP,  // 16384
        START                   = appinput.Event.Type.START,
        DRAW                    = appinput.Event.Type.DRAW,
    }

    bool
    is_app () {
        return (type >= Type.APP);
    }

    bool
    is_input () {
        return (type > Type.NONE) && (type < Type.APP);
    }

    string
    toString () {
        import std.format : format;
        import std.conv   : to;

        if (is_app)
            return format!"APP   : %s: %s" (type,_app);
        else
        if (is_input)
            return format!"INPUT : %s: %s" (type,_input);
        else
            return format!"_     : %s    " (type);
    }
}
