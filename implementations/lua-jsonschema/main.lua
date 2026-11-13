-- The jsonschema-benchmark entry point for api7's jsonschema on LuaJIT, which generates Lua code for each schema
-- (draft 4, 6 and 7): read the instances into memory, parse each with lua-cjson (timed), compile the schema (timed),
-- validate every instance once cold, warm up, validate once more warm. Prints "cold,warm,compile,parse" in
-- nanoseconds and exits non-zero if any instance is invalid.
local ffi = require 'ffi'
local cjson = require 'cjson'
local jsonschema = require 'jsonschema'

ffi.cdef [[
  typedef struct { long tv_sec; long tv_nsec; } timespec;
  int clock_gettime(int clock_id, timespec *tp);
]]
local CLOCK_MONOTONIC = 1
local ts = ffi.new 'timespec'
local function now()
  ffi.C.clock_gettime(CLOCK_MONOTONIC, ts)
  return tonumber(ts.tv_sec) * 1e9 + tonumber(ts.tv_nsec)
end

local WARMUP_ITERATIONS = 100
local MAX_WARMUP_TIME = 1e10

local function read_file(path)
  local f = assert(io.open(path, 'rb'))
  local text = f:read '*a'
  f:close()
  return text
end

local function validate_all(validator, instances, report)
  local valid = true
  for i = 1, #instances do
    if not validator(instances[i]) then
      if report then io.stderr:write('Error validating instance ', i - 1, '\n') end
      valid = false
    end
  end
  return valid
end

-- Arrays keep a metatable, so that an empty array is not taken for an empty object.
cjson.decode_array_with_array_mt(true)
local schema = cjson.decode(read_file(arg[1]))
local lines = {}
for line in read_file(arg[2]):gmatch '[^\n]+' do lines[#lines + 1] = line end

local parse_start = now()
local instances = {}
for i = 1, #lines do instances[i] = cjson.decode(lines[i]) end
local parse = now() - parse_start

local compile_start = now()
local validator = jsonschema.generate_validator(schema)
local compile = now() - compile_start

local cold_start = now()
local valid = validate_all(validator, instances, true)
local cold = now() - cold_start

local iterations = math.ceil(MAX_WARMUP_TIME / math.max(cold, 1))
for _ = 1, math.min(iterations, WARMUP_ITERATIONS) do validate_all(validator, instances, false) end

local warm_start = now()
validate_all(validator, instances, false)
local warm = now() - warm_start

io.write(string.format('%d,%d,%d,%d\n', cold, warm, compile, parse))
os.exit(valid and 0 or 1)
