
version (XXX):

version (linux) {
version (LIBINPUT) {
    auto
    Whats () {
        import appinput      : Events;
        import lo_level.what : AppEvent;
        return Events!AppEvent ();
    }
}
else 
version (EVDEV) {
    auto
    Whats () {
        return new _Whats ();
    }
    class
    _Whats {
        What what = new What ();

        int
        opApply (int delegate (What what) dg) {
            auto _dev = Evdev ("/dev/input/mouse1");

            while (1) {
                foreach (what; _dev) {
                    writeln (what);

                    if (auto result = dg (what))
                        return result;
                }

                import core.sys.posix.unistd : sleep;
                sleep (1);
            }

//            return 0;    
        }    
    }

    struct 
    Evdev {
        string _device;  // "/dev/input/la5"
        File   _file;
        What    front;


        this (string device) {
            this._device = device;
            this.front   = new What ();
            _init ();
        }

        void 
        _init () {
            import std.string           : toStringz;
            import core.sys.posix.fcntl : fcntl,O_NONBLOCK,F_SETFL,F_GETFL;

            // FILE._file
            _file.open (_device,"rb");

            // set the file description to non blocking
            int flags = fcntl (_file.fileno,F_GETFL,0);
            fcntl (_file.fileno,F_SETFL,flags|O_NONBLOCK);

            writeln (1);
            // can also use select/poll to check to see if data is available
        }

        void 
        popFront () {
            import std.format : format;

            ubyte[] buffer;
            buffer.length = front.event.sizeof;
            writeln ("length: ", buffer.length);

            auto _readed = _file.rawRead (buffer);

            writeln (buffer);
            //front.event = _readed;

            if (_readed.length != 1)
                throw new InputException (
                    format!
                        "error reading: %s\n"
                        (_device)
                );
        }

        bool
        empty () { 
            import core.sys.posix.poll : poll,pollfd,POLLIN,POLLHUP,POLLERR;
            import core.stdc.errno     : errno,EAGAIN,EINTR;

            auto fds = pollfd (_file.fileno,POLLIN);

            // n = total number of file descriptors that have las 
            int n = poll(
                &fds, // file descriptors
                1,    // number of file descriptors
                0     // timeout ms
            );

            // empty
            if (n == 0)
                return true;

            // check error
            if (n < 0) {
                // soft error - no las
                if (errno == EAGAIN || errno == EINTR)
                    return true; // empty
                else
                    throw new InputException ("EINVAL");
            }

            if (fds.revents & POLLIN) 
                return false; // OK, not-empty
            else
                return true;  // empty
        }
    }

    class
    InputException : Exception {
        this (string s) {
            super (s);
        }
    }
}
}
else
version (SDL) {
    import std.format : format;
    import std.conv   : to;
    import std.string : fromStringz; 
    import std.string : toStringz;
    import bindbc.sdl;

    const DEFAULT_WINDOW_W = 1024;
    const DEFAULT_WINDOW_H = 480;

    auto
    Whats () {
        return new _Whats ();
    }
    class
    _Whats {  // from Window
        What what;
        bool _go;

        int
        opApply (int delegate (What what) dg) {
            _init ();  // SDL
            _go = true;
            what = new What ();
            what.sdl_window   = new_sdl_window ("SDL");
            what.sdl_renderer = new_sdl_renderer (what.sdl_window);

            while (_go) {
                read_sdl:
                while (SDL_WaitEvent (&what.sdl) > 0) {
                    if (auto result = dg (what))
                        return result;
                    if (what.sdl.type == SDL_QUIT) {
                        _go = false;
                        break read_sdl;
                    }
                }
            }        

            return 0;    
        }
    }

    void 
    init_sdl () {
        // SDL
        version (Windows)
            SDLSupport _sdl_support = loadSDL ("sdl2.dll");
        else
            SDLSupport _sdl_support = loadSDL ();

        if (_sdl_support != sdlSupport) {
            if (_sdl_support == SDLSupport.noLibrary) 
                throw new Exception ("The SDL shared library failed to load");
            else 
            if (_sdl_support == SDLSupport.badLibrary) 
                throw new Exception ("One or more symbols failed to load. The likely cause is that the shared library is for a lower version than bindbc-sdl was configured to load (via SDL_204, GLFW_2010 etc.)");
        }

        //if (SDL_Init (SDL_INIT_EVERYTHING) < 0)
        if (SDL_Init (SDL_INIT_VIDEO | SDL_INIT_EVENTS) < 0)
            throw new SDLException ("The SDL init failed");

        SDL_version sdl_ver;
        SDL_GetVersion (&sdl_ver);

        // IMG
        if (bindSDLImage) {
            auto _sdl_image_support = loadSDLImage ();
            if (_sdl_image_support < sdlImageSupport) // 2.6.3
                throw new Exception ("The SDL_Image shared library failed to load");
            
            auto flags = IMG_INIT_PNG; // | IMG_INIT_JPG;
            if (IMG_Init (flags) != flags)
                throw new IMGException ("The SDL_Image init failed");
        }

        // TTF
        if (bindSDLTTF) {
            auto _sdl_ttf_support = loadSDLTTF (); // SDLTTFSupport
            if (_sdl_ttf_support < sdlTTFSupport) // 2.0.20
                throw new TTFException ("The SDL_TTF shared library failed to load:");
            
            if (TTF_Init () == -1)
                throw new TTFException ("Failed to initialise SDL_TTF");
        }

        // GFX
        // libSDL2_gfx.so
        version (SDL_GFX) {
            auto _sdl_gfx_support = loadSDLgfx (); // SDLgfxSupport
            if (_sdl_gfx_support != SDLgfxSupport.SDLgfx) {
                if (_sdl_gfx_support == SDLgfxSupport.noLibrary) 
                    throw new Exception ("The SDL GFX shared library failed to load");
                else 
                if (_sdl_gfx_support == SDLgfxSupport.badLibrary) 
                    throw new Exception ("SDL GFX: One or more symbols failed to load.");
            }
        }
    }

    //
    SDL_Window*
    new_sdl_window (string window_title) {
        // Window
        auto window = 
            SDL_CreateWindow (
                window_title.toStringz, // "SDL2 Window",
                SDL_WINDOWPOS_CENTERED,
                SDL_WINDOWPOS_CENTERED,
                DEFAULT_WINDOW_W, DEFAULT_WINDOW_H,
                SDL_WINDOW_RESIZABLE
            );

        if (!window)
            throw new SDLException ("Failed to create window");

        // Update
        SDL_UpdateWindowSurface (window);

        return window;
    }


    //
    SDL_Renderer* 
    new_sdl_renderer (SDL_Window* window) {
        return SDL_CreateRenderer (window, -1, SDL_RENDERER_SOFTWARE);
    }

    //
    class 
    SDLException : Exception {
        this (string msg) {
            super (format!"%s: %s" (SDL_GetError().to!string, msg));
        }
    }

    class 
    TTFException : Exception{
        this (string s) {
            super (
                format!"%s: %s"(s, fromStringz(TTF_GetError()))
            );
        }
    }

    class 
    IMGException : Exception{
        this (string s) {
            super (
                format!"%s: %s"(s, fromStringz(IMG_GetError()))
            );
        }
    }

    void
    _init () {
        init_sdl ();
    }
}
else {  // default version
    auto
    Whats () {
        return new _Whats ();
    }
    class
    _Whats {
        What what = new What ();

        int
        opApply (int delegate (What what) dg) {
            if (auto result = dg (what))
                return result;

            return 0;    
        }    
    }
}
