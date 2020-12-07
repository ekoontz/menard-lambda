(defproject menard-lambda "0.0.1-SNAPSHOT"
  :description "Some great description"

  :global-vars {*warn-on-reflection* true}

  :dependencies [[org.clojure/clojure "1.10.1"]
                 [org.clojure/data.json "0.2.7"]
                 [dag_unify "1.9.8"]
                 [fierycod/holy-lambda "0.0.6"]
                 [menard "1.4.0-SNAPSHOT"]]
  :uberjar-name "output.jar"
  :aot :all)
