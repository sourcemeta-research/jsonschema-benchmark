import java.io.Reader;
import java.io.FileReader;
import java.io.BufferedReader;
import java.io.InputStreamReader;

import java.util.ArrayList;
import java.util.List;

import gnu.getopt.Getopt;  // old school :-)
import gnu.getopt.LongOpt;

import json_model.ModelChecker;
import json_model.Checker;
import json_model.JSON;

/**
 * JSON Schema Benchmark
 */
public class JsonSchemaBenchmark
{
    /** Exit with a message */
    static void exit(int status, String message)
    {
        if (message != null && status > 0)
            System.err.println(message);
        if (message != null && status == 0)
            System.out.println(message);
        System.exit(status);
    }

    /** Run JSON Schema Benchmark */
    static public void main(String[] args)
        throws JSON.Exception
    {
        // option management
        Getopt g = new Getopt("JsonSchemaBenchmark", args, "Dj:", new LongOpt[] {
            new LongOpt("debug", LongOpt.NO_ARGUMENT, null, 'D'),
            new LongOpt("json", LongOpt.REQUIRED_ARGUMENT, null, 'j')
        });

        boolean debug = false;
        String json_lib = "GSON";

        int c;
        while ((c = g.getopt()) != -1)
        {
            switch (c)
            {
                case 'D':
                    debug = true;
                    break;
                case 'j':
                    json_lib = g.getOptarg();
                    break;
                case '?':
                    exit(2, "unexpected option");
            }
        }

        // load and initialize with JSON library
        JSON json;
        try {
            if (json_lib.equals("GSON"))
                json_lib = "json_model.GSON";
            else if (json_lib.equals("Jackson"))
                json_lib = "json_model.Jackson";
            else if (json_lib.equals("JSONP"))
                json_lib = "json_model.JSONP";
            // else keep as is and cross fingers
            json = (JSON) Class.forName(json_lib).getDeclaredConstructor().newInstance();
        }
        catch (Exception e) {
            exit(3, "unexpected JSON library: " + json_lib + ": " + e);
            return;
        }

        int errors = 0;

        ModelChecker checker = new Schema();
        checker.init(json);
        Checker check = checker.get("");

        List<Object> jsons = new ArrayList();

        // process file arguments as jsonl
        for (int idx = g.getOptind(); idx < args.length; idx++)
        {
            String fname = args[idx];

            // get file contents
            try {
                Reader reader = fname.equals("-") ?
                    new InputStreamReader(System.in) : new FileReader(fname);
                BufferedReader bf = new BufferedReader(reader);
                for (String line: bf.lines().toList())
                    jsons.add(json.fromJSON(line));
            }
            catch (Exception e) {
                exit(4, "error on file " + fname + ": " + e);
                return;
            }
        }

        Object[] values = jsons.toArray();

        // overhead estimation
        int count = 0;
        long overhead_start = System.nanoTime();
        for (Object value: values)
            if (value != null)
                count++;
        double overhead_delay = 0.001 * (System.nanoTime() - overhead_start);

        // cold run
        if (debug)
            System.err.println("cold run");
        long cold_start = System.nanoTime();
        for (Object value: values)
            if (!check.call(value))
                errors++;
        double cold_run = 0.001 * (System.nanoTime() - cold_start);

        // warmup
        int niters = 1 + (int) (10 * 1E6 / cold_run);
        if (niters > 1000) niters = 1000;
        if (debug)
            System.err.println("warmup loop: " + niters);
        while (niters-- > 0)
            for (Object value: values)
                check.call(value);

        // measure
        if (debug)
            System.err.println("hot run");
        long start = System.nanoTime();
        for (Object value: values)
            check.call(value);
        double hot_run = 0.001 * (System.nanoTime() - start);

        // show result
        String sdelay = String.format("%.03f", hot_run);
        String odelay = String.format("%.03f", overhead_delay);
        System.err.println("Java validation: pass=" + (values.length - errors) +
                           " fail=" + errors + " " + sdelay + " µs [" + odelay + " µs]");
        System.out.println((long) (1000 * cold_run + 0.5) + "," + (long) (1000 * hot_run + 0.5));

        // cleanup
        checker.free();
        System.exit(errors > 0 ? 1 : 0);
    }
}
