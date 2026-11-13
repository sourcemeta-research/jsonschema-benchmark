(defproject jsonschema-benchmark-clojure "0.0.0"
  :dependencies [[org.clojure/clojure "1.12.3"]
                 [luposlip/json-schema "0.4.8"]]
  :main benchmark.core
  :profiles {:uberjar {:aot :all}})
