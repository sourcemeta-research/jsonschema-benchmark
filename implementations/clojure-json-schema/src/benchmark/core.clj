;; The jsonschema-benchmark entry point for luposlip/json-schema (draft 4, 6 and 7, over everit-json-schema): read the
;; instances into memory, prepare the schema (timed), validate every instance once cold, warm up, validate once more
;; warm. Prints "cold,warm,compile,parse" in nanoseconds and exits non-zero if any instance is invalid.
;;
;; The library validates JSON text or Clojure data, and turns either into org.json values on every call: it takes no
;; parsed value of its own. So instances are validated from their text, the cold and warm figures include parsing, and
;; the parse figure is only taking a copy of each line.
(ns benchmark.core
  (:require [clojure.string :as string]
            [json-schema.core :as json-schema])
  (:gen-class))

(def warmup-iterations 100)
(def max-warmup-time 10000000000)

(defn- valid? [schema instance]
  (try
    (json-schema/validate schema instance)
    true
    (catch clojure.lang.ExceptionInfo _ false)))

(defn- validate-all [schema instances report]
  (reduce-kv (fn [valid i instance]
               (if (valid? schema instance)
                 valid
                 (do (when report (binding [*out* *err*] (println "Error validating instance" i)))
                     false)))
             true
             instances))

(defn -main [schema-path instances-path]
  (let [schema-text (slurp schema-path)
        lines (vec (remove string/blank? (string/split-lines (slurp instances-path))))
        parse-start (System/nanoTime)
        instances (mapv #(String. ^String %) lines)
        parse (- (System/nanoTime) parse-start)
        compile-start (System/nanoTime)
        schema (json-schema/prepare-schema schema-text)
        compile (- (System/nanoTime) compile-start)
        cold-start (System/nanoTime)
        valid (validate-all schema instances true)
        cold (- (System/nanoTime) cold-start)
        iterations (quot (+ max-warmup-time (max cold 1) -1) (max cold 1))]
    (dotimes [_ (min iterations warmup-iterations)] (validate-all schema instances false))
    (let [warm-start (System/nanoTime)
          _ (validate-all schema instances false)
          warm (- (System/nanoTime) warm-start)]
      (println (str cold "," warm "," compile "," parse))
      (shutdown-agents)
      (System/exit (if valid 0 1)))))
