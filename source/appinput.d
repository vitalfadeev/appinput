import libinput_d      : libinput_event_type;
import libinput_struct : LibInput,InpEvent;
//import libinput_struct;
//import app;

alias __Event (AppEvent) = _Event!(InpEvent,AppEvent);

auto
Events (AppEvent) () {
    alias AppInput = _AppInput!AppEvent;
    alias Event    = __Event!AppEvent;
    return 
        _Events!(LibInput,AppInput,Event,InpEvent,AppEvent) 
            (LibInput (null), AppInput ());
}
struct
_Events (LibInput,AppInput,Event,InpEvent,AppEvent) {
    // 2 source
    //  - app       -> ...
    //  - libinput  -> InpEvent
    // read ALL app events
    // then read 1 libinput event
    LibInput libinput;
    AppInput appinput;
    Source  _source;

    // front
    // back
    // empty
    // popFront
    // popBack
    // opOpAssign (string op : "~")

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

    Event
    front () {
        // read all appinput
        // then one libinput
        final
        switch (_source) {
            case Source.APP   : return Event (appinput.front);
            case Source.INPUT : return Event (libinput.front);
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
    opOpAssign (string op : "~") (InpEvent event) {
        libinput ~= event;
    }
    void
    opOpAssign (string op : "~") (AppEvent event) {
        appinput ~= event;
    }
    void
    opOpAssign (string op : "~") (Event event) {
        if (event.is_app)
            appinput ~= event._app;
        else
        if (event.is_input)
            libinput ~= event._input;
    }
}

enum
Source {
    APP,
    INPUT,
}

struct
_Event (InpEvent,AppEvent) {
    // ushort
    // libinput_event*
    //   ushort
    //   void*
    Type          type;
    union {
        AppEvent _app;
        InpEvent _input;  // (event = libinput_get_event (li)) != null
    }

    this (Type type) {
        this.type = type;
        if (is_app) {
            import std.conv : to;
            import std.traits : OriginalType,CommonType;
            this._app = AppEvent (type.to!(OriginalType!Type).to!(AppEvent.Type));
        }
    }

    this (AppEvent.Type type) {
        import std.conv : to;
        import std.traits : OriginalType,CommonType;
        this.type = type.to!(OriginalType!Type).to!(Type);
        this._app = AppEvent (type);
    }

    this (AppEvent event) {
        import std.conv : to;
        import std.traits : OriginalType,CommonType;
        this.type = event.type.to!(OriginalType!Type).to!(Type);
        this._app = event;
    }

    this (InpEvent event) {
        import std.conv : to;
        import std.traits : OriginalType,CommonType;
        this.type   = event.type.to!(OriginalType!Type).to!(Type);
        this._input = event;
    }

    bool
    opCast (T) () if (is (T == bool)) {
        return (type != 0);
    }

    // Type
    mixin (clone_enum_mix!(InpEvent,AppEvent,"Type"));  // Type

    bool
    is_app () {
        return (type > InpEvent.Type.max);
    }

    bool
    is_input () {
        return (type <= InpEvent.Type.max) && (type != 0);
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

import std.container : DList;


struct
_AppInput (AppEvent) {
    DList!AppEvent _super;
    alias _super this;

    void
    popFront () {
        _super.removeFront ();
    }
}


string 
clone_enum_mix (E1,E2,string name) () {
    import std.traits : EnumMembers,fullyQualifiedName;
    import std.traits : OriginalType,CommonType;
    import std.format : format;

    alias T = CommonType!(OriginalType!(E1.Type),OriginalType!(E2.Type));

    string s = "enum " ~name~ " : " ~T.stringof~ " {\n";
    foreach (member; EnumMembers!(E1.Type)) {
        s ~= format("%s = %s.Type.%s,\n", member, E1.stringof, member);
        //s ~= format("%s = %s.%s,\n", member, fullyQualifiedName!E1, member);
    }
    foreach (member; EnumMembers!(E2.Type)) {
        s ~= format("%s = %s.Type.%s,\n", member, E2.stringof, member);
        //s ~= format("%s = %s.%s,\n", member, fullyQualifiedName!E2, member);
    }
    s ~= "}";
    return s;
}
