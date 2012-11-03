import std.math;

T clamp(T)(T x, T min, T max)
{
    if (x < min)
    {
        return min;
    }
    if (x > max)
    {
        return max;
    }
    return x;
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