module grains;

import std.c.stdlib;
import std.stdio;
import std.math;
import std.algorithm;
import std.parallelism;
import std.range;
import std.random;
import derelict.sdl2.sdl;

import app, util;

enum grain_type : Uint8
{
    SAND = 0,
    BLACK_POWDER,
    COUNT,
}

enum grain_flag : Uint8
{
    FREE     = 0,
    ALIVE    = 1,
    SLEEPING = 2,
    FIRE     = 4,
}

mixin template grain_mixin()
{
    grain_flag flags;
    float x, y;
    float vx, vy;
    float r, g, b;
}

struct grain_t
{
    mixin grain_mixin;
}


class grains_state_t
{
public:
    app_t * app;
    grain_type type;
    void * grains;
    size_t count;
    size_t stride;
    this(ref app_t a)
    {
        app = &a;
    }

    grain_t * find_first_free()
    {
        foreach (grain_index; iota(0, count))
        {
            grain_t * grain = cast(grain_t *)(grains + grain_index * stride);
            if (grain.flags == grain_flag.FREE)
            {
                return grain;
            }
        }
        return null;
    }

    void self_update(double dt)
    {
        foreach (grain_index; parallel(iota(0, count)))
        {
            grain_t * grain = cast(grain_t *)(grains + grain_index * stride);
            if ((grain.flags & grain_flag.SLEEPING) == 0)
            {
                grain.x += grain.vx * dt;
                grain.y += grain.vy * dt;
                grain.vx *= 0.99f;
                grain.vy *= 0.99f;
                if (grain.vx * grain.vx + grain.vy * grain.vy < 0.0001)
                {
                    grain.flags |= grain_flag.SLEEPING;
                }
                if (grain.x < app.min_x || grain.x > app.max_x)
                {
                    grain.vx = -grain.vx;
                }
                if (grain.y < app.min_y || grain.y > app.max_y)
                {
                    grain.vy = -grain.vy;
                }
                grain.x = clamp(grain.x, app.min_x, app.max_x);
                grain.y = clamp(grain.y, app.min_y, app.max_y);
            }
        }
    }

    void update(double dt)
    {

    }

}

struct sand_grain_t
{
    mixin grain_mixin;
}

class sand_grains_state_t : grains_state_t
{
    this(ref app_t a, size_t n)
    {
        super(a);
        type = grain_type.SAND;
        count = n;
        stride = sand_grain_t.sizeof;
        grains = malloc(stride * count);
        foreach (grain_index; 0..count)
        {
            grain_t * grain = cast(grain_t *)(grains + grain_index * stride);
            grain.flags = cast(grain_flag)(grain_flag.ALIVE | grain_flag.SLEEPING);
            grain.x = uniform(0.0f, 1.0f);
            grain.y = uniform(0.0f, 1.0f);
            grain.vx = 0;
            grain.vy = 0;
            hsv_to_rgb(grain.x, 0.8f, 0.8f, grain.r, grain.g, grain.b);
        }
    }

    ~this()
    {
        free(grains);
    }
}

struct black_powder_grain_t
{
    mixin grain_mixin;
    float fuse;
}


class black_powder_grains_state_t : grains_state_t
{
    this(ref app_t a, size_t n)
    {
        super(a);
        type = grain_type.BLACK_POWDER;
        count = n;
        stride = black_powder_grain_t.sizeof;
        grains = malloc(stride * count);
        foreach (grain_index; 0..count)
        {
            black_powder_grain_t * grain = cast(black_powder_grain_t *)(grains + grain_index * stride);
            grain.flags = cast(grain_flag)(grain_flag.ALIVE | grain_flag.SLEEPING);
            grain.x = uniform(0.0f, 1.0f);
            grain.y = uniform(0.0f, 1.0f);
            grain.vx = 0;
            grain.vy = 0;
            grain.fuse = uniform(0.01f, 0.1f);
            grain.r = 0.0;
            grain.g = 1.0;
            grain.b = 0.0;
            //hsv_to_rgb(grain.x, 1.0f, 1.0f, grain.r, grain.g, grain.b);
        }
    }

    ~this()
    {
        free(grains);
    }

    void self_update(double dt)
    {
        grains_state_t.self_update(dt);
        foreach (grain_index; 0..count)
        {
            black_powder_grain_t * grain = cast(black_powder_grain_t *)(grains + grain_index * stride);
            if (grain.flags & grain_flag.ALIVE)
            {
                if (grain.flags & grain_flag.FIRE)
                {
                    grain.fuse -= dt;
                }
            }
        }
    }

    void update(double dt)
    {
        foreach (grain_index; 0..count)
        {
            black_powder_grain_t * grain = cast(black_powder_grain_t *)(grains + grain_index * stride);
            if (grain.flags & grain_flag.ALIVE && grain.fuse <= 0.0)
            {
                grains_shockwave(*app, grain.x, grain.y, 0.01);
                grain.flags = grain_flag.FREE;
            }
        }
    }
}


void grains_state_init(ref app_t app)
{
    app.grains_states = new grains_state_t[grain_type.COUNT];
    app.grains_states[grain_type.SAND] = new sand_grains_state_t(app, 100_000);
    app.grains_states[grain_type.BLACK_POWDER] = new black_powder_grains_state_t(app, 1000);
}

void grains_update(ref app_t app, double dt)
{
    foreach (grain_state; app.grains_states)
    {
        grain_state.self_update(dt);
    }

    foreach (grain_state; app.grains_states)
    {
        grain_state.update(dt);
    }
}

void grains_shockwave(ref app_t app, float x, float y, float energy)
{
    foreach (grain_state; app.grains_states)
    {
        foreach (grain_index; parallel(iota(0, grain_state.count)))
        {
            grain_t * grain = cast(grain_t *)(grain_state.grains + grain_index * grain_state.stride);
            if (grain.flags & grain_flag.ALIVE)
            {
                float dx = grain.x - x;
                float dy = grain.y - y;
                float d2 = max(0.0000001f, dx * dx + dy * dy);
                grain.vx += dx / d2 * energy;
                grain.vy += dy / d2 * energy;
                grain.flags &= ~grain_flag.SLEEPING;
                if (d2 < 0.004)
                {
                    grain.flags |= grain_flag.FIRE;
                }
            }
        }
    }
}

void grains_draw(ref app_t app, SDL_Surface * surface)
{
    if (SDL_MUSTLOCK(surface))
    {
        SDL_LockSurface(surface);
    }
    ubyte * pixels = cast(ubyte *)surface.pixels;
    uint stride = surface.format.BytesPerPixel;
    uint pitch = surface.pitch;

    foreach (grain_state; app.grains_states)
    {
        foreach (grain_index; parallel(iota(0, grain_state.count)))
        {
            grain_t * grain = cast(grain_t *)(grain_state.grains + grain_index * grain_state.stride);
            int x, y;
            if (grain.flags & grain_flag.ALIVE)
            {
                app_world_to_screen(app, grain.x, grain.y, x, y);
                if (x >= 0 && x < app.width && y >= 0 && y < app.height)
                {
                    pixels[x * stride + y * pitch]     = cast(ubyte)(255 * grain.b);
                    pixels[x * stride + y * pitch + 1] = cast(ubyte)(255 * grain.g);
                    pixels[x * stride + y * pitch + 2] = cast(ubyte)(255 * grain.r);
                }
            }
        }
    }

    if (SDL_MUSTLOCK(surface))
    {
        SDL_UnlockSurface(surface);
    }
}

