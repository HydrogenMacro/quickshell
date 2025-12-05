#include <math.h>
#include <stdio.h>
#include <spa/param/audio/format-utils.h>

const float PI = 3.14159265;
void fourier_trans(float* samples, uint32_t samples_len, uint32_t sample_rate, float* ft_samples_output, int ft_samples_count)
{
    int min_hz = 0;
    int max_hz = 2000;
    
    for (int ft_sample_idx = 0; ft_sample_idx < ft_samples_count; ft_sample_idx++) {
        float log_scale = (float) ft_sample_idx / (float) ft_samples_count;
        float x = floorf((float)(max_hz - min_hz) * log_scale + min_hz);
        float v = 0.;
        for (int t = 0; t < samples_len; t++) {
            float a = (float)t / (float) sample_rate;
            v += samples[t] * cosf(-2. * PI * x * a);
        }
        
        ft_samples_output[ft_sample_idx] = v;
    }

}