pragma(lib, "DerelictUtil.lib");
pragma(lib, "DerelictSDL2.lib");

import std.stdio;
import std.math;
import std.algorithm, std.parallelism, std.range, std.random;
import derelict.sdl2.sdl;

enum grain_type : Uint8
{
    SAND = 0,
    BLACK_POWDER,
    COUNT,
}

enum grain_flag : Uint8
{
    FREE  = 0,
    ALIVE = 1,
    FIRE  = 2,
}

struct grain_t
{
    grain_type type;
    grain_flag flags;
    float x, y;
    float vx, vy;
    float status;
    float r, g, b;
}

struct grains_state_t
{
    grain_t[] grains;
}

struct app_t
{
    SDL_Window * window;
    int width, height;
    float min_x, min_y, max_x, max_y;
    int current_state;
    grains_state_t[2] state_buffers;
}

void hsv_to_rgb(float h, float s, float v, ref float r, ref float g, ref float b)
{
    float c = v * s;
    float m = v - c;
    float x = c * (1 - abs(h * 6 % 2 - 1));
    if (h >= 0 && h < 1.0f/6.0f)
    {
        r = c;
        g = x;
        b = 0.0f;
    }
    else if (h >= 1.0f/6.0f && h < 1.0f/3.0f)
    {
        r = x;
        g = c;
        b = 0.0f;
    }
    else if (h >= 1.0f/3.0f && h < 1.0f/2.0f)
    {
        r = 0.0f;
        g = c;
        b = x;
    }
    else if (h >= 1.0f/2.0f && h < 2.0f/3.0f)
    {
        r = 0.0f;
        g = x;
        b = c;
    }
    else if (h >= 2.0f/3.0f && h < 5.0f/6.0f)
    {
        r = x;
        g = 0.0f;
        b = c;
    }
    else if (h >= 5.0f/6.0f && h < 1.0f)
    {
        r = c;
        g = 0.0f;
        b = x;
    }
    r += m;
    g += m;
    b += m;
}

void app_screen_to_world(ref app_t app, int x, int y, ref float ox, ref float oy)
{
    ox = cast(float)x / cast(float)app.width * (app.max_x - app.min_x) + app.min_x;
    oy = cast(float)y / cast(float)app.height * (app.max_y - app.min_y) + app.min_y;
}

void app_world_to_screen(ref app_t app, float x, float y, ref int ox, ref int oy)
{
    ox = cast(int)((x - app.min_x) / (app.max_x - app.min_x) * app.width);
    oy = cast(int)((y - app.min_y) / (app.max_y - app.min_y) * app.height);
}

void grains_state_init(ref grains_state_t grain_state)
{
    grain_state.grains.length = 100_000;
    foreach (ref grain; grain_state.grains)
    {
        grain.type = cast(grain_type)dice(100, 1);
        grain.flags = grain_flag.ALIVE;
        grain.x = uniform(0.0f, 1.0f);
        grain.y = uniform(0.0f, 1.0f);
        grain.vx = 0;
        grain.vy = 0;
        hsv_to_rgb(grain.x, 1.0f, 1.0f, grain.r, grain.g, grain.b);
    }
}

void grains_update(ref grains_state_t grain_state, double dt)
{
    foreach (ref grain; taskPool.parallel(grain_state.grains, 1000))
    //foreach (ref grain; grain_state.grains)
    {
        if (grain.flags & grain_flag.ALIVE)
        {
            grain.x += grain.vx * dt;
            grain.y += grain.vy * dt;
            grain.vx *= 0.99f;
            grain.vy *= 0.99f;
            if (grain.flags & grain_flag.FIRE && grain.type == grain_type.BLACK_POWDER)
            {
                grain.flags = grain_flag.FREE;
                grains_shockwave(grain_state, grain.x, grain.y, 0.005);
            }
            //grain.vy += 0.98 * dt * uniform(0.0f, 1.0f);
        }
    }
}

void grains_shockwave(ref grains_state_t grain_state, float x, float y, float energy)
{
    foreach (ref grain; taskPool.parallel(grain_state.grains, 1000))
    //foreach (ref grain; grain_state.grains)
    {
        if (grain.flags & grain_flag.ALIVE)
        {
            float dx = grain.x - x;
            float dy = grain.y - y;
            float d2 = dx * dx + dy * dy;
            grain.vx += dx / d2 * energy;
            grain.vy += dy / d2 * energy;
            if (d2 < 0.004)
            {
                grain.flags |= grain_flag.FIRE;
            }
        }
    }
}

void grains_draw(ref app_t app, ref grains_state_t grain_state, SDL_Surface * surface)
{
    if (SDL_MUSTLOCK(surface))
    {
        SDL_LockSurface(surface);
    }
    ubyte * pixels = cast(ubyte *)surface.pixels;
    uint stride = surface.format.BytesPerPixel;
    uint pitch = surface.pitch;

    foreach (grain; taskPool.parallel(grain_state.grains, 1000))
    //foreach (grain; grain_state.grains)
    {
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

    if (SDL_MUSTLOCK(surface))
    {
        SDL_UnlockSurface(surface);
    }
}

void grains_run(ref app_t app)
{
    SDL_Surface * screen = SDL_GetWindowSurface(app.window);
    SDL_Event event;
    bool running = true;
    while (running)
    {
        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
            case SDL_QUIT:
                running = false;
                break;
            case SDL_KEYDOWN:
                if (event.key.keysym.sym == SDLK_ESCAPE)
                {
                    running = false;
                }
                break;
            case SDL_MOUSEBUTTONDOWN:
                float x, y;
                app_screen_to_world(app, event.button.x, event.button.y, x, y);
                grains_shockwave(app.state_buffers[app.current_state], x, y, 0.1);
                break;
            default:
                break;
            }
        }

        ulong updateStart = SDL_GetPerformanceCounter();
        grains_update(app.state_buffers[app.current_state], 0.001);
        ulong updateEnd = SDL_GetPerformanceCounter();
        //writeln("Update: ", updateEnd - updateStart);

        SDL_FillRect(screen, null, 0x00000000);

        ulong drawStart = SDL_GetPerformanceCounter();
        grains_draw(app, app.state_buffers[app.current_state], screen);
        ulong drawEnd = SDL_GetPerformanceCounter();
        //writeln("Draw: ", drawEnd - drawStart);
        //writeln("Freq: ", SDL_GetPerformanceFrequency() / 60);

        SDL_UpdateWindowSurface(app.window);
    }
}

void main() {
    DerelictSDL2.load();

    SDL_Init(SDL_INIT_VIDEO);

    app_t app;
    app.width = 800;
    app.height = 600;
    app.min_x = 0;
    app.min_y = 0;
    app.max_x = 1;
    app.max_y = cast(float)app.height / cast(float)app.width;
    app.current_state = 0;
    grains_state_init(app.state_buffers[0]);

    app.window = SDL_CreateWindow("Grains", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, app.width, app.height, SDL_WINDOW_SHOWN | SDL_WINDOW_BORDERLESS);

    grains_run(app);

    SDL_Quit();
}