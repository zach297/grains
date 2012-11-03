module devices;

import std.stdio;
import derelict.sdl2.sdl;
import app;

class device_state_t
{
protected:
    app_t * app;
public:
    this(ref app_t a)
    {
        app = &a;
    }
    void update(double dt)
    {

    }
    void draw(SDL_Surface * surface)
    {

    }
}

class genners_state_t
{
protected:
    app_t * app;
public:
    this(ref app_t a)
    {
        app = &a;
    }
    void update(double dt)
    {

    }
    void draw(SDL_Surface * surface)
    {
    
    }
}

alias void function(device_state_t device_state_ptr) device_init;

device_init[] device_inits;

void devices_init(ref app_t app)
{
    app.device_states = new device_state_t[device_inits.length];
    foreach (size_t dev_index, device_init dev_init; device_inits)
    {
        dev_init(app.device_states[dev_index]);
    }
}

void genner_init(device_state_t device_state_ptr)
{
    writeln("Genner Init");
}

static this()
{
    device_inits ~= &genner_init;
}