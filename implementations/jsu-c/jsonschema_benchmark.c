#include <stdio.h>
#include <unistd.h>
#include <assert.h>
#include <time.h>
#include <getopt.h>
#include <errno.h>
#include <string.h>
#define str_eq(s1, s2) (strcmp(s1, s2) == 0)

#include <json-model.h>

// NOTE CLOCK_REALTIME resolution seems low at 0.250 µs
static clockid_t current_clock = CLOCK_MONOTONIC;

// return realtime(?) µs
static INLINE double now(void)
{
    struct timespec ts;
    if (unlikely(clock_gettime(current_clock, &ts)))
    {
        fprintf(stderr, "cannot get time (%d): %s\n", errno, strerror(errno));
        exit(2);
    }
    return 1000000.0 * ts.tv_sec + 0.001 * ts.tv_nsec;
}

int main(int argc, char* argv[])
{
    // get options
    int opt;
    bool debug = false;

    const struct option options[] = {
        { "debug", no_argument, NULL, 'D' },
        { "clock", required_argument, NULL, 'C' },
        { NULL, 0, NULL, 0 }
    };

    while ((opt = getopt_long(argc, argv, "DC:", options, NULL)) != -1)
    {
        switch (opt) {
            case 'D':
                debug = true;
                break;
            case 'C':
                if (str_eq(optarg, "monotonic") || str_eq(optarg, "m"))
                    current_clock = CLOCK_MONOTONIC;
                else if (str_eq(optarg, "realtime") || str_eq(optarg, "r"))
                    current_clock = CLOCK_REALTIME;
#ifdef CLOCK_PROCESS_CPUTIME_ID
                else if (str_eq(optarg, "process") || str_eq(optarg, "p"))
                    current_clock = CLOCK_PROCESS_CPUTIME_ID;
#endif
#ifdef CLOCK_THREAD_CPUTIME_ID
                else if (str_eq(optarg, "thread") || str_eq(optarg, "t"))
                    current_clock = CLOCK_THREAD_CPUTIME_ID;
#endif
                else {
                    fprintf(stderr, "unexpected clock %s for [mrpt]\n", optarg);
                    return 3;
                }
                break;
            case '?':
            default:
                fprintf(stderr, "unexpected option encountered\n");
                return 3;
        }
    }

    // initialization
    const char *error = check_model_init();
    assert(error == NULL);

    const jm_check_fun_t checker = check_model_map("");
    assert(checker != NULL);

    size_t size = 1024;
    int nvalues = 0;
    json_t **values = (json_t **) malloc(sizeof(json_t *) * size);

    // load all as jsonl
    for (int i = optind; i < argc; i++)
    {
        FILE *input = fopen(argv[i], "r");

        if (input == NULL)
        {
            fprintf(stderr, "%s: ERROR while opening file\n", argv[i]);
            exit(3);
        }

        json_error_t error;
        json_t *value;
        while ((value = json_loadf(input,
                                   JSON_DISABLE_EOF_CHECK|JSON_DECODE_ANY|JSON_ALLOW_NUL,
                                   &error)))
        {
            if (nvalues == size) {
                size *= 2;
                values = (json_t **) realloc(values, sizeof(json_t *) * size);
            }
            values[nvalues++] = value;
        }
    }

    // run once
    int nfail = 0;
    double cold_start = now();
    for (int i = 0; i < nvalues; i++)
        if (unlikely(!checker(values[i], NULL, NULL)))
            nfail++;
    double cold_delay = now() - cold_start;
    int npass = nvalues - nfail;

    // max 1000 warmup runs up to 10 seconds, probably useless
    int ten_secs_loop = 1 + (int) (10000000.0 / cold_delay);
    int warmup = ten_secs_loop < 1000 ? ten_secs_loop : 1000;
    for (int n = warmup; n; n--)
        for (int i = 0; i < nvalues; i++)
            checker(values[i], NULL, NULL);

    // collect performance data, possibly over a loop… of 1
    double start = now();
    for (int i = 0; i < nvalues; i++)
        checker(values[i], NULL, NULL);
    double delay = now() - start;

    // report
    fprintf(stderr, "C validation: pass=%d fail=%d %.03f µs\n", npass, nfail, delay);
    fprintf(stdout, "%lld,%lld\n",
            (long long int) (1000 * cold_delay + 0.5), (long long int) (1000 * delay + 0.5));

    check_model_free();

    return nfail? 1: 0;
}
