-- The jsonschema-benchmark entry point for lua-schema (draft 4 to 2020-12): read the instances into memory, parse each
-- with dkjson (timed), compile the schema (timed), validate every instance once cold, warm up, validate once more
-- warm. Prints "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
local json = require 'dkjson'
local clock = require 'posix.time'

local WARMUP_ITERATIONS = 100
local MAX_WARMUP_TIME = 1e10

local function now()
  local t = clock.clock_gettime(clock.CLOCK_MONOTONIC)
  return t.tv_sec * 1000000000 + t.tv_nsec
end

local function read_file(path)
  local f = assert(io.open(path, 'rb'))
  local text = f:read 'a'
  f:close()
  return text
end

local DIALECTS = {
  ['https://json-schema.org/draft/2020-12/schema'] = 'schema.dialect.draft2020-12',
  ['https://json-schema.org/draft/2019-09/schema'] = 'schema.dialect.draft2019-09',
  ['http://json-schema.org/draft-07/schema'] = 'schema.dialect.draft-07',
  ['http://json-schema.org/draft-06/schema'] = 'schema.dialect.draft-06',
  ['http://json-schema.org/draft-04/schema'] = 'schema.dialect.draft-04',
}

-- dkjson marks arrays and objects with a metatable and decodes null to a sentinel; lua-schema is told about both, as
-- Bowtie's harness does.
local null = io.stderr
local function setup(dialect)
  local schema = require 'schema'
  if dialect then require(dialect) end
  schema.json.null = null
  schema.json.is_array = function(data)
    if type(data) == 'table' then
      local mt = getmetatable(data)
      return not mt or mt.__jsontype == 'array'
    end
    return false
  end
  schema.json.is_object = function(data)
    if type(data) == 'table' then
      local mt = getmetatable(data)
      return not mt or mt.__jsontype == 'object'
    end
    return false
  end
  return schema
end

local function validate_all(validator, instances, report)
  local valid = true
  for i = 1, #instances do
    if not validator:validate(instances[i]).valid then
      if report then io.stderr:write('Error validating instance ', i - 1, '\n') end
      valid = false
    end
  end
  return valid
end

local raw_schema = json.decode(read_file(arg[1]), 1, null)
local lines = {}
for line in read_file(arg[2]):gmatch '[^\n]+' do lines[#lines + 1] = line end

local parse_start = now()
local instances = {}
for i = 1, #lines do instances[i] = json.decode(lines[i], 1, null) end
local parse = now() - parse_start

local dialect = type(raw_schema) == 'table' and type(raw_schema['$schema']) == 'string'
  and DIALECTS[raw_schema['$schema']:gsub('#$', '')] or nil
local compile_start = now()
local validator = setup(dialect).new(raw_schema)
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
