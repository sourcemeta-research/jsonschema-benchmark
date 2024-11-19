#include <sourcemeta/jsontoolkit/json.h>
#include <sourcemeta/jsontoolkit/jsonl.h>
#include <sourcemeta/jsontoolkit/jsonschema.h>

#include <sourcemeta/blaze/compiler.h>
#include <sourcemeta/blaze/evaluator.h>

#include <linux/perf_event.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>

#include <chrono>
#include <filesystem>
#include <iostream>
#include <vector>

#define WARMUP_ITERATIONS 100L
#define MAX_WARMUP_TIME 10000000000

static long perf_event_open(struct perf_event_attr *hw_event, pid_t pid, int cpu, long group_fd, unsigned long flags){
  long fd;
  fd = syscall(SYS_perf_event_open, hw_event, pid, cpu, group_fd, flags);
  if (fd == -1) {
    fprintf(stderr, "Error creating event");
    exit(EXIT_FAILURE);
  }

  return fd;
}

struct read_format {
  uint64_t nr;
  struct {
    uint64_t value;
    uint64_t id;
  } values[6];
};

class PerfEvents {
  private:
    struct perf_event_attr pea;
    unsigned long branch_predict_id;
    long branch_predict_fd;
    unsigned long branch_miss_id;
    long branch_miss_fd;
    unsigned long cache_access_id;
    long cache_access_fd;
    unsigned long cache_miss_id;
    long cache_miss_fd;
    unsigned long cycles_id;
    long cycles_fd;
    unsigned long instr_id;
    long instr_fd;

    void newHWEvent(struct perf_event_attr *newEvent, unsigned long type, long *fd, long group_fd, unsigned long *id) {
      memset(newEvent, 0, sizeof(struct perf_event_attr));
      newEvent->type = PERF_TYPE_HARDWARE;
      newEvent->size = sizeof(struct perf_event_attr);
      newEvent->config = type;
      newEvent->disabled = 1;
      newEvent->exclude_kernel = 1;
      newEvent->exclude_hv = 1;
      newEvent->read_format = PERF_FORMAT_GROUP | PERF_FORMAT_ID;
      *fd = perf_event_open(newEvent, 0, -1, group_fd, 0);
      ioctl((int) *fd, PERF_EVENT_IOC_ID, id);
    }
  public:
    PerfEvents() {
      newHWEvent(&pea, PERF_COUNT_HW_BRANCH_INSTRUCTIONS, &branch_predict_fd, -1, &branch_predict_id);
      newHWEvent(&pea, PERF_COUNT_HW_BRANCH_MISSES, &branch_miss_fd, branch_predict_fd, &branch_miss_id);
      newHWEvent(&pea, PERF_COUNT_HW_CACHE_REFERENCES, &cache_access_fd, branch_predict_fd, &cache_access_id);
      newHWEvent(&pea, PERF_COUNT_HW_CACHE_MISSES, &cache_miss_fd, branch_predict_fd, &cache_miss_id);
      newHWEvent(&pea, PERF_COUNT_HW_CPU_CYCLES, &cycles_fd, branch_predict_fd, &cycles_id);
      newHWEvent(&pea, PERF_COUNT_HW_INSTRUCTIONS, &instr_fd, branch_predict_fd, &instr_id);
    }

    void start() {
      ioctl((int) branch_predict_fd, PERF_EVENT_IOC_RESET, PERF_IOC_FLAG_GROUP);
      ioctl((int) branch_predict_fd, PERF_EVENT_IOC_ENABLE, PERF_IOC_FLAG_GROUP);
    }

    void stop() {
      ioctl((int) branch_predict_fd, PERF_EVENT_IOC_DISABLE, PERF_IOC_FLAG_GROUP);
    }

    void print() {
      char buf[4096];
      struct read_format *rf = (struct read_format*) buf;
      unsigned long branch_predicts = 0;
      unsigned long branch_misses = 0;
      unsigned long cache_accesses = 0;
      unsigned long cache_misses = 0;
      unsigned long cycles = 0;
      unsigned long instructions = 0;

      read((int) branch_predict_fd, buf, sizeof(buf));
      for (unsigned long i = 0; i < rf->nr; i++) {
        if (rf->values[i].id == branch_predict_id) {
          branch_predicts = rf->values[i].value;
        } else if (rf->values[i].id == branch_miss_id) {
          branch_misses = rf->values[i].value;
        } else if (rf->values[i].id == cache_access_id) {
          cache_accesses = rf->values[i].value;
        } else if (rf->values[i].id == cache_miss_id) {
          cache_misses = rf->values[i].value;
        } else if (rf->values[i].id == cycles_id) {
          cycles = rf->values[i].value;
        } else if (rf->values[i].id == instr_id) {
          instructions = rf->values[i].value;
        }
      }

      std::cerr << "       Cycles: " << cycles << "\n";
      std::cerr << " Instructions: " << instructions << "\n";
      std::cerr << " Cache misses: " << cache_misses << "/" << cache_accesses << " = " << (((double) cache_misses / cache_accesses) * 100) << "%\n";
      std::cerr << "Branch misses: " << branch_misses << "/" << branch_predicts << " = " << (((double) branch_misses / branch_predicts) * 100) << "%\n";
    }

    ~PerfEvents() {
      close((int) branch_miss_fd);
      close((int) cache_access_fd);
      close((int) cache_miss_fd);
      close((int) cycles_fd);
      close((int) instr_fd);
      close((int) branch_predict_fd);
    }
};

bool validate_all(auto &context, const auto &instances, const auto &schema_template) {
  for (std::size_t num = 0; num < instances.size(); num++) {
    context.prepare(instances[num]);
    const auto result{
        sourcemeta::blaze::evaluate(schema_template, context)};
    if (!result) {
      std::cerr << "Error validating instance " << num << "\n";
      return false;
    }
  }

  return true;
}

int validate(const std::filesystem::path &example) {
  const auto schema{
      sourcemeta::jsontoolkit::from_file(example / "schema.json")};
  auto stream{sourcemeta::jsontoolkit::read_file(example / "instances.jsonl")};
  std::vector<sourcemeta::jsontoolkit::JSON> instances;
  for (const auto &instance : sourcemeta::jsontoolkit::JSONL{stream}) {
    instances.push_back(instance);
  }

  const auto compile_start{std::chrono::high_resolution_clock::now()};
  const auto schema_template{sourcemeta::blaze::compile(
      schema, sourcemeta::jsontoolkit::default_schema_walker,
      sourcemeta::jsontoolkit::official_resolver,
      sourcemeta::blaze::default_schema_compiler,
      sourcemeta::blaze::Mode::FastValidation)};

  const auto compile_end{std::chrono::high_resolution_clock::now()};
  const auto compile_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      compile_end - compile_start)};

  sourcemeta::blaze::EvaluationContext context;
  PerfEvents pe;

  const auto cold_start{std::chrono::high_resolution_clock::now()};

  pe.start();
  if (!validate_all(context, instances, schema_template)) {
    return EXIT_FAILURE;
  }
  pe.stop();

  std::cerr << "Cold\n==============================\n";
  pe.print();
  std::cerr << "\n";

  const auto cold_end{std::chrono::high_resolution_clock::now()};
  const auto cold_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      cold_end - cold_start)};

  const auto iterations = 1 + ((MAX_WARMUP_TIME - 1) / cold_duration.count());
  for (int i = 0; i < std::min(iterations, WARMUP_ITERATIONS); i++) {
    validate_all(context, instances, schema_template);
  }

  const auto warm_start{std::chrono::high_resolution_clock::now()};

  pe.start();
  validate_all(context, instances, schema_template);
  pe.stop();

  std::cerr << "Warm\n==============================\n";
  pe.print();
  std::cerr << "\n";

  const auto warm_end{std::chrono::high_resolution_clock::now()};
  const auto warm_duration{std::chrono::duration_cast<std::chrono::nanoseconds>(
      warm_end - warm_start)};

  std::cout << cold_duration.count() << "," << warm_duration.count() << "," << compile_duration.count() << "\n";

  return EXIT_SUCCESS;
}

int main(int argc, char **argv) {
  if (argc < 2) {
    std::cerr << "Usage: " << argv[0] << " <schema>\n";
    return EXIT_FAILURE;
  }

  try {
    const std::filesystem::path example{argv[1]};
    return validate(example);
  } catch (const std::exception &e) {
    std::cerr << "Error during Blaze benchmark: " << e.what() << "\n";
    return EXIT_FAILURE;
  }
}
