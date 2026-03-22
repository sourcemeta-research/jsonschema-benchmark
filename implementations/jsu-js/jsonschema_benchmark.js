import { parseArgs } from 'node:util'
import fs from 'node:fs/promises'

import { jm_set_rx } from 'json_model_runtime'
import { createRequire } from 'node:module'
const require = createRequire(import.meta.url)

import { check_model_init, check_model_map, check_model_free } from './schema.js'

export default async function main()
{
    const options = {
      // TODO --help --list
      'debug': { type: 'boolean', short: 'D' },
      're2': { type: 'boolean' },
      'regexp': { type: 'boolean' },
    }

    const args = parseArgs({options, allowPositionals: true})

    // reset regular expression engine
    if (args.values.regexp)
        jm_set_rx(RegExp)
    if (args.values.re2)
        jm_set_rx(require('re2'))

    let debug = args.values.debug
    let errors = 0
    check_model_init()
    const checker = check_model_map.get("")

    // load files contents
    const values = []
    for (const fname of args.positionals)
    {
        const data = await fs.readFile(fname, {encoding: 'UTF-8'})
        values.push(...data.split("\n").slice(0, -1).map(s => JSON.parse(s)))
    }

    // overhead estimation
    let count = 0
    const overhead_start = performance.now()
    for (const v of values)
        if (v !== null)
            count++
    const overhead_delay = performance.now() - overhead_start  // ms

    // cold run
    if (debug)
        console.error("cold run")
    const cold_start = performance.now()
    for (const v of values)
        if (!checker(v, "", null))
            errors++
    const cold_delay = performance.now() - cold_start  // ms

    // warm-up so as to trigger JIT
    const WARMUP_MAX_TIME = 10.0  // seconds
    const WARMUP_ITERATIONS = 1000  // unless too long
    const max_iterations = Math.ceil(WARMUP_MAX_TIME * 1000.0 / cold_delay)
    const warmup_iterations = Math.min(WARMUP_ITERATIONS, max_iterations)

    if (debug)
        console.error("warmup loop ${warmup_iterations}")

    for (let i = 0; i < warmup_iterations; i++)
        for (const v of values)
            checker(v, '', null)

    // warm run
    if (debug)
        console.error("hot run")
    const start = performance.now()
    for (const v of values)
        checker(v, "", null)
    const delay = performance.now() - start  // ms

    console.error(`js validation: pass=${values.length - errors} fail=${errors}`,
                  `${(1000.0 * delay).toFixed(3)} µs [${(1000.0 * overhead_delay).toFixed(3)} µs]`)

    console.log((1000000.0 * cold_delay).toFixed(0) + ',' + (1000000.0 * delay).toFixed(0))

    check_model_free()
    process.exit(errors ? 1 : 0)
}

main()
