! The jsonschema-benchmark entry point for Corvus.JsonSchema's Fortran binding (corvus-json-schema), mirroring
! implementations/corvus-cpp/main.cpp: read the instances into memory, parse each into a document (timed), compile
! (timed), validate every document once cold, warm up, validate once more warm. Prints "cold,warm,compile,parse" in
! nanoseconds and exits non-zero if any instance is invalid. The binding's parse copies the text (the C library's
! borrowed parse is not in the binding), so the parse figure includes that copy.
program corvus_fortran_benchmark
  use, intrinsic :: iso_fortran_env, only: error_unit, int64
  use corvus_json_schema, only: validator_t, document_t
  implicit none

  integer(int64), parameter :: WARMUP_ITERATIONS = 100
  integer(int64), parameter :: MAX_WARMUP_TIME = 10000000000_int64

  character(:), allocatable :: schema_path, instances_path, schema, contents, errmsg
  type(validator_t) :: validator
  type(document_t), allocatable :: instances(:)
  integer(int64), allocatable :: line_start(:), line_end(:)
  integer(int64) :: count, i, start, finish, iterations, rate
  integer(int64) :: parse_start, parse_end, compile_start, compile_end, cold_start, cold_end, warm_start, warm_end
  integer :: stat
  logical :: valid, ignored

  if (command_argument_count() /= 2) then
    write (error_unit, "(a)") "Usage: corvus_fortran_benchmark <schema.json> <instances.jsonl>"
    error stop 1
  end if
  schema_path = argument(1)
  instances_path = argument(2)
  schema = read_file(schema_path)
  contents = read_file(instances_path)

  ! The non-empty lines of the instances file.
  count = 0
  allocate (line_start(1024), line_end(1024))
  start = 1
  do while (start <= len(contents, int64))
    finish = index(contents(start:), new_line("a"), kind=int64)
    if (finish == 0) then
      finish = len(contents, int64)
    else
      finish = start + finish - 2
    end if
    if (finish >= start) then
      if (count == size(line_start, kind=int64)) call grow()
      count = count + 1
      line_start(count) = start
      line_end(count) = finish
    end if
    start = finish + 2
  end do
  allocate (instances(count))

  call system_clock(count_rate=rate)

  call system_clock(parse_start)
  do i = 1, count
    call instances(i)%parse(contents(line_start(i):line_end(i)), stat=stat, errmsg=errmsg)
    if (stat /= 0) call fail("parse", errmsg)
  end do
  call system_clock(parse_end)

  call system_clock(compile_start)
  call validator%compile(schema, stat=stat, errmsg=errmsg)
  call system_clock(compile_end)
  if (stat /= 0) call fail("compile", errmsg)

  call system_clock(cold_start)
  valid = validate_all(.true.)
  call system_clock(cold_end)

  iterations = 1 + (MAX_WARMUP_TIME - 1) / max(ns(cold_start, cold_end), 1_int64)
  do i = 1, min(iterations, WARMUP_ITERATIONS)
    ignored = validate_all(.false.)
  end do

  call system_clock(warm_start)
  ignored = validate_all(.false.)
  call system_clock(warm_end)

  print "(i0,',',i0,',',i0,',',i0)", ns(cold_start, cold_end), ns(warm_start, warm_end), &
    ns(compile_start, compile_end), ns(parse_start, parse_end)
  if (.not. valid) error stop 1

contains

  function validate_all(report) result(all_valid)
    logical, intent(in) :: report
    logical :: all_valid
    integer(int64) :: j
    all_valid = .true.
    do j = 1, count
      if (.not. validator%is_valid_document(instances(j), stat=stat)) then
        if (report) write (error_unit, "(a,i0)") "Error validating instance ", j - 1
        all_valid = .false.
      end if
    end do
  end function validate_all

  ! Nanoseconds between two system_clock counts.
  function ns(from, to) result(elapsed)
    integer(int64), intent(in) :: from, to
    integer(int64) :: elapsed
    if (rate == 1000000000_int64) then
      elapsed = to - from
    else
      elapsed = int(real(to - from, kind=8) * (1.0d9 / real(rate, kind=8)), int64)
    end if
  end function ns

  subroutine grow()
    integer(int64), allocatable :: bigger(:)
    allocate (bigger(2 * size(line_start, kind=int64)))
    bigger(1:count) = line_start(1:count)
    call move_alloc(bigger, line_start)
    allocate (bigger(2 * size(line_end, kind=int64)))
    bigger(1:count) = line_end(1:count)
    call move_alloc(bigger, line_end)
  end subroutine grow

  subroutine fail(what, message)
    character(*), intent(in) :: what
    character(:), allocatable, intent(in) :: message
    write (error_unit, "(a)") "Error during Corvus benchmark: " // what // ": " // message
    error stop 1
  end subroutine fail

  function argument(n) result(value)
    integer, intent(in) :: n
    character(:), allocatable :: value
    integer :: length
    call get_command_argument(n, length=length)
    allocate (character(length) :: value)
    call get_command_argument(n, value)
  end function argument

  function read_file(path) result(text)
    character(*), intent(in) :: path
    character(:), allocatable :: text
    integer :: unit, size_in_bytes, ios
    open (newunit=unit, file=path, access="stream", form="unformatted", action="read", status="old", iostat=ios)
    if (ios /= 0) then
      write (error_unit, "(a)") "Error reading " // path
      error stop 1
    end if
    inquire (unit=unit, size=size_in_bytes)
    allocate (character(size_in_bytes) :: text)
    if (size_in_bytes > 0) read (unit) text
    close (unit)
  end function read_file

end program corvus_fortran_benchmark
