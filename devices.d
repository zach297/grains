module devices;

import std.algorithm;
import std.parallelism;
import std.random;
import std.range;
import std.stdio;
import derelict.sdl2.sdl;
import app, grains, util;

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

void print_struct(T)(T instance)
{
    auto members = __traits(allMembers, T);
    foreach (int i, ref member; instance.tupleof)
    {
        writeln(typeof(member).stringof, ' ', members[i], ';');
    }
}

class genners_state_t : device_state_t
{
private:
    struct genner_state_t
    {
        float[2] p1, p2;
        float spawn_rate;
        double extra_time;
    }

    genner_state_t[] genners;
public:
    this(ref app_t a)
    {
        super(a);
        genners = new genner_state_t[1];
        genners[0].p1 = [0.2,0.4];
        genners[0].p2 = [0.25,0.45];
        genners[0].spawn_rate = 10000;
        genners[0].extra_time = 0;
        print_struct(genners[0]);
    }

    void update(double dt)
    {
        foreach (ref genner; genners)
        {
            genner.extra_time += dt;

            // Calculate the launch vector of the genner.
            float[2] launch_vector = genner.p1[] - genner.p2[];
            normalize(launch_vector);
            swap(launch_vector[0], launch_vector[1]);
            launch_vector[0] = -launch_vector[0];

            // Spawn as many grains as we have time for.
            double spawn_cost = 1.0 / genner.spawn_rate;
            while (genner.extra_time > spawn_cost)
            {
                float[2] velocity = launch_vector[] * uniform(4.0f,10.0f);
                grain_t * grain = app.grains_states[grain_type.SAND].find_first_free();
                if (grain)
                {
                    float[2] position = linear_interp(genner.p1, genner.p2, uniform(0.0f, 1.0f));
                    grain.flags = cast(grain_flag)(grain_flag.ALIVE);
                    grain.x = position[0];
                    grain.y = position[1];
                    grain.vx = velocity[0];
                    grain.vy = velocity[1];
                    hsv_to_rgb(uniform(0.0f, 1.0f), 1.0f, 1.0f, grain.r, grain.g, grain.b);
                }
                else
                {
                    break;
                }
                genner.extra_time -= spawn_cost;
            }
        }
    }
    void draw(SDL_Surface * surface)
    {

    }
}

class drainers_state_t : device_state_t
{
private:
    struct drainer_state_t
    {
        float[2] p1, p2;
    }

    drainer_state_t[] drainers;
public:
    this(ref app_t a)
    {
        super(a);
        drainers = new drainer_state_t[1];
        drainers[0].p1 = [0, 1];
        drainers[0].p2 = [1, 1];
    }

    void update(double dt)
    {
        foreach (drainer; drainers)
        {
            foreach (grain_state; app.grains_states)
            {
                foreach (grain_index; parallel(iota(0, grain_state.count)))
                {
                    grain_t * grain = cast(grain_t *)(grain_state.grains + grain_index * grain_state.stride);
                    
                    if (grain.y >= 1.0f)
                    {
                        grain.flags = grain_flag.FREE;
                    }
                }
            }
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

void device_init_template(T)(ref app_t app, ref device_state_t device_state_ref)
{
    device_state_ref = new T(app);
}

static this()
{
    device_inits ~= &device_init_template!(genners_state_t);
    device_inits ~= &device_init_template!(drainers_state_t);
}