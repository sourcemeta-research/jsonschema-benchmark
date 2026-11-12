// The jsonschema-benchmark entry point for Corvus.JsonSchema's C library (corvus-json-schema), through its C API,
// mirroring implementations/corvus-cpp/main.cpp: read the instances into memory, parse each into a document (timed),
// compile (timed), validate every document once cold, warm up, validate once more warm. Prints
// "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
#define _POSIX_C_SOURCE 199309L
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "corvus_json_schema.h"

#define WARMUP_ITERATIONS 100LL
#define MAX_WARMUP_TIME 10000000000LL

static long long now_ns(void) {
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (long long)t.tv_sec * 1000000000LL + t.tv_nsec;
}

static char* read_file(const char* path, size_t* len) {
    FILE* f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);
    char* data = malloc((size_t)size + 1);
    if (!data || fread(data, 1, (size_t)size, f) != (size_t)size) {
        fclose(f);
        free(data);
        return NULL;
    }
    fclose(f);
    data[size] = '\0';
    *len = (size_t)size;
    return data;
}

static int fail(const char* what) {
    cjs_str message = cjs_last_error_message();
    fprintf(stderr, "Error during Corvus benchmark: %s: %.*s\n", what, (int)message.len, message.ptr);
    return 1;
}

static bool validate_all(const cjs_validator* v, cjs_document** instances, size_t count, bool report) {
    bool all_valid = true;
    for (size_t i = 0; i < count; i++) {
        bool valid = false;
        if (cjs_validator_validate_document(v, instances[i], &valid) != CJS_OK || !valid) {
            if (report) fprintf(stderr, "Error validating instance %zu\n", i);
            all_valid = false;
        }
    }
    return all_valid;
}

int main(int argc, char** argv) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <schema.json> <instances.jsonl>\n", argv[0]);
        return 1;
    }
    size_t schema_len = 0, contents_len = 0;
    char* schema = read_file(argv[1], &schema_len);
    char* contents = read_file(argv[2], &contents_len);
    if (!schema || !contents) {
        fprintf(stderr, "Error reading the input files\n");
        return 1;
    }

    // The lines, borrowed from the file's contents, which stay unchanged until the documents are freed.
    size_t capacity = 1024, count = 0;
    const char** line_start = malloc(capacity * sizeof *line_start);
    size_t* line_len = malloc(capacity * sizeof *line_len);
    for (size_t start = 0; start < contents_len;) {
        const char* nl = memchr(contents + start, '\n', contents_len - start);
        size_t end = nl ? (size_t)(nl - contents) : contents_len;
        if (end > start) {
            if (count == capacity) {
                capacity *= 2;
                line_start = realloc(line_start, capacity * sizeof *line_start);
                line_len = realloc(line_len, capacity * sizeof *line_len);
            }
            line_start[count] = contents + start;
            line_len[count] = end - start;
            count++;
        }
        start = end + 1;
    }
    cjs_document** instances = calloc(count ? count : 1, sizeof *instances);

    long long parse_start = now_ns();
    for (size_t i = 0; i < count; i++) {
        if (cjs_document_parse_borrowed(line_start[i], line_len[i], &instances[i]) != CJS_OK) return fail("parse");
    }
    long long parse_end = now_ns();

    cjs_validator* v = NULL;
    long long compile_start = now_ns();
    if (cjs_compile(schema, schema_len, NULL, &v) != CJS_OK) return fail("compile");
    long long compile_end = now_ns();

    long long cold_start = now_ns();
    bool valid = validate_all(v, instances, count, true);
    long long cold_end = now_ns();

    long long cold = cold_end - cold_start;
    long long iterations = 1 + (MAX_WARMUP_TIME - 1) / (cold > 1 ? cold : 1);
    if (iterations > WARMUP_ITERATIONS) iterations = WARMUP_ITERATIONS;
    for (long long i = 0; i < iterations; i++) validate_all(v, instances, count, false);

    long long warm_start = now_ns();
    validate_all(v, instances, count, false);
    long long warm_end = now_ns();

    printf("%lld,%lld,%lld,%lld\n", cold, warm_end - warm_start, compile_end - compile_start, parse_end - parse_start);

    for (size_t i = 0; i < count; i++) cjs_document_free(instances[i]);
    cjs_validator_free(v);
    free(instances);
    free(line_start);
    free(line_len);
    free(contents);
    free(schema);
    return valid ? 0 : 1;
}
