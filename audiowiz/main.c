#include <stdio.h>
#include <errno.h>
#include <math.h>
#include <signal.h>
#include <spa/param/audio/format-utils.h>
#include <pipewire/pipewire.h>
#include "fourier_trans.c"

struct data
{
    struct pw_main_loop *loop;
    struct pw_stream *stream;

    struct spa_audio_info format;

    float min_mel;
    float max_mel;
    int ft_samples_count;
    float *sample_datas[2];
    float *ft_output;
};

/* our data processing function is in general:
 *
 *  struct pw_buffer *b;
 *  b = pw_stream_dequeue_buffer(stream);
 *
 *  .. consume stuff in the buffer ...
 *
 *  pw_stream_queue_buffer(stream, b);
 */
static void on_process(void *userdata)
{
    struct data *data = userdata;
    struct pw_buffer *b;
    struct spa_buffer *buf;
    float *samples;
    uint32_t n, n_channels, n_samples;

    if ((b = pw_stream_dequeue_buffer(data->stream)) == NULL)
    {
        pw_log_warn("out of buffers: %m");
        return;
    }

    buf = b->buffer;
    if ((samples = buf->datas[0].data) == NULL)
        return;

    int rate = data->format.info.raw.rate;
    n_channels = data->format.info.raw.channels;
    n_samples = buf->datas[0].chunk->size / sizeof(float);
    int samples_len = n_samples / n_channels;

    if (data->sample_datas[0] == NULL)
    {
        data->sample_datas[0] = malloc(samples_len * sizeof(float));
        data->sample_datas[1] = malloc(samples_len * sizeof(float));
    }
    for (int c = 0; c <= 1; c++)
    {
        for (int i = 0; i < samples_len; i++)
        {
            data->sample_datas[c][i] = samples[i * 2 + c];
        }
    }
    double rmsSum = 0;
    for (int i = 0; i < data->ft_samples_count; i++)
    {
        rmsSum +=
            data->sample_datas[0][i] * data->sample_datas[0][i];
    }
    float rms = sqrt(rmsSum);
    fourier_trans(data->sample_datas[0], samples_len, rate, data->ft_output, data->ft_samples_count, data->min_mel, data->max_mel);
    for (int i = 0; i < data->ft_samples_count; i++)
    {
        if (i != 0) printf(" ");
        printf("%f", data->ft_output[i]);
    }
    printf("|");
    printf("%.4f", rms);
    printf("\n");
    pw_stream_queue_buffer(data->stream, b);
}    


static void
on_stream_param_changed(void *_data, uint32_t id, const struct spa_pod *param)
{
    struct data *data = _data;

    /* NULL means to clear the format */
    if (param == NULL || id != SPA_PARAM_Format)
        return;

    if (spa_format_parse(param, &data->format.media_type, &data->format.media_subtype) < 0)
        return;

    /* only accept raw audio */
    if (data->format.media_type != SPA_MEDIA_TYPE_audio ||
        data->format.media_subtype != SPA_MEDIA_SUBTYPE_raw)
        return;

    /* call a helper function to parse the format for us. */
    spa_format_audio_raw_parse(param, &data->format.info.raw);

    int _channels = data->format.info.raw.channels;
}

static const struct pw_stream_events stream_events = {
    PW_VERSION_STREAM_EVENTS,
    .param_changed = on_stream_param_changed,
    .process = on_process,
};

static void do_quit(void *userdata, int signal_number)
{
    struct data *data = userdata;
    pw_main_loop_quit(data->loop);
}

int main(int argc, char *argv[])
{
    struct data data = {
        0,
    };
    if (argc != 4)
    {
        fprintf(stderr, "3 arguments required, only found %d\nusage: audiowiz <min_mel: number> <min_mel: number> <min_mel: number> <samples_count: number>", argc - 1);
        return 1;
    }
    data.min_mel = atof(argv[1]);
    if (data.min_mel <= 0.00001)
        data.min_mel = 0.00001;
    data.max_mel = atof(argv[2]);
    if (data.min_mel >= data.max_mel)
    {
        fprintf(stderr, "min_mel of %f is greater than max_mel of %f", data.min_mel, data.max_mel);
        return 1;
    }
    data.ft_samples_count = atoi(argv[3]);
    if (data.ft_samples_count <= 0)
    {
        fprintf(stderr, "sample count of %d is invalid", data.ft_samples_count);
        return 1;
    }
    data.ft_output = malloc(data.ft_samples_count * sizeof(float));
    const struct spa_pod *params[1];
    uint8_t buffer[1024];
    struct pw_properties *props;
    struct spa_pod_builder b = SPA_POD_BUILDER_INIT(buffer, sizeof(buffer));

    pw_init(&argc, &argv);

    /* make a main loop. If you already have another main loop, you can add
     * the fd of this pipewire mainloop to it. */
    data.loop = pw_main_loop_new(NULL);

    pw_loop_add_signal(pw_main_loop_get_loop(data.loop), SIGINT, do_quit, &data);
    pw_loop_add_signal(pw_main_loop_get_loop(data.loop), SIGTERM, do_quit, &data);

    /* Create a simple stream, the simple stream manages the core and remote
     * objects for you if you don't need to deal with them.
     *
     * If you plan to autoconnect your stream, you need to provide at least
     * media, category and role properties.
     *
     * Pass your events and a user_data pointer as the last arguments. This
     * will inform you about the stream state. The most important event
     * you need to listen to is the process event where you need to produce
     * the data.
     */
    props = pw_properties_new(PW_KEY_MEDIA_TYPE, "Audio",
                              PW_KEY_MEDIA_CATEGORY, "Capture",
                              PW_KEY_MEDIA_ROLE, "Music",
                              PW_KEY_STREAM_CAPTURE_SINK, "True",
                              NULL);

    data.stream = pw_stream_new_simple(
        pw_main_loop_get_loop(data.loop),
        "audio-capture",
        props,
        &stream_events,
        &data);

    /* Make one parameter with the supported formats. The SPA_PARAM_EnumFormat
     * id means that this is a format enumeration (of 1 value).
     * We leave the channels and rate empty to accept the native graph
     * rate and channels. */
    params[0] = spa_format_audio_raw_build(&b, SPA_PARAM_EnumFormat,
                                           &SPA_AUDIO_INFO_RAW_INIT(
                                                   .format = SPA_AUDIO_FORMAT_F32));

    /* Now connect this stream. We ask that our process function is
     * called in a realtime thread. */
    pw_stream_connect(data.stream,
                      PW_DIRECTION_INPUT,
                      PW_ID_ANY,
                      PW_STREAM_FLAG_AUTOCONNECT |
                          PW_STREAM_FLAG_MAP_BUFFERS |
                          PW_STREAM_FLAG_RT_PROCESS,
                      params, 1);

    /* and wait while we let things run */
    pw_main_loop_run(data.loop);

    pw_stream_destroy(data.stream);
    pw_main_loop_destroy(data.loop);
    pw_deinit();
    free(data.sample_datas[0]);
    free(data.sample_datas[1]);
    free(data.ft_output);
    return 0;
}