module app;

import std.stdio;
import std.math;
import derelict.sdl2.sdl;
import grains, devices;

struct app_t
{
    SDL_Window * window;
    int width, height;
    float min_x, min_y, max_x, max_y;
    grains_state_t[grain_type.COUNT] grains_states;
    device_state_t[] device_states;
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

void app_run(ref app_t app)
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
                grains_shockwave(app, x, y, 0.1);
                break;
            default:
                break;
            }
        }

        ulong updateStart = SDL_GetPerformanceCounter();
        grains_update(app, 0.001);
        ulong updateEnd = SDL_GetPerformanceCounter();
        //writeln("Update: ", updateEnd - updateStart);

        SDL_FillRect(screen, null, 0x00000000);

        ulong drawStart = SDL_GetPerformanceCounter();
        grains_draw(app, screen);
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
    devices_init(app);
    grains_state_init(app);

    app.window = SDL_CreateWindow("Grains", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, app.width, app.height, SDL_WINDOW_SHOWN | SDL_WINDOW_BORDERLESS);

    app_run(app);

    SDL_Quit();
}
