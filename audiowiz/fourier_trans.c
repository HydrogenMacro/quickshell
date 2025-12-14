#include <math.h>
#include <stdio.h>
#include <spa/param/audio/format-utils.h>

// https://en.wikipedia.org/wiki/Mel_scale
float mel_to_hz(float mel) {
    return 700. * (powf(10., mel / 2595.) - 1.);
}
const float PI = 3.141592653589;
void fourier_trans(float* samples, uint32_t samples_len, uint32_t sample_rate, float* ft_samples_output, int ft_samples_count, float min_mel, float max_mel)
{   
    for (int ft_sample_idx = 0; ft_sample_idx < ft_samples_count; ft_sample_idx++) {
        float progress = (float) ft_sample_idx / (float) ft_samples_count;
        float x = mel_to_hz((max_mel - min_mel) * progress + min_mel);
        
        float v = 0.;
        float w = 0.;
        for (int t = 0; t < samples_len; t++) {
            float a = (float)t / (float) sample_rate;
            v += (float) samples[t] * cosf(-2. * PI * x * a);
            w += (float) samples[t] * sinf(-2. * PI * x * a);
        }
        
        ft_samples_output[ft_sample_idx] = v*v + w*w;
    }
}

