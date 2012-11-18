module devices;

import std.random;
import std.stdio;
import derelict.sdl2.sdl;
import app, grains;

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

class genners_state_t : device_state_t
{
public:
    this(ref app_t a)
    {
        super(a);
    }

    void update(double dt)
    {
        black_powder_grain_t * grain = cast(black_powder_grain_t*)app.grains_states[grain_type.BLACK_POWDER].find_first_free();
        if (grain != null)
        {
            grain.flags = grain_flag.ALIVE;
            grain.x = uniform(0.0, 1.0f);
            grain.y = uniform(0.0, 1.0f);
            grain.vx = 0;
            grain.vy = 0;
            grain.fuse = uniform(0.01f, 0.1f);
        }
    }
    void draw(SDL_Surface * surface)
    {

    }
}

alias void function(ref app_t app, ref device_state_t device_state_ref) device_init;

device_init[] device_inits;

void devices_init(ref app_t app)
{
    app.device_states = new device_state_t[device_inits.length];
    foreach (size_t dev_index, device_init dev_init; device_inits)
    {
        dev_init(app, app.device_states[dev_index]);
    }
}

void devices_update(ref app_t app, double dt)
{
    foreach (dev; app.device_states)
    {
        dev.update(dt);
    }
}

void devices_draw(ref app_t app, SDL_Surface * surface)
{
    foreach (dev; app.device_states)
    {
        dev.draw(surface);
    }
}

void genner_init(ref app_t app, ref device_state_t device_state_ref)
{
    device_state_ref = new genners_state_t(app);
}

static this()
{
    device_inits ~= &genner_init;
}