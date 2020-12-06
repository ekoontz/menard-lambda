(defproject menard-lambda "0.0.1-SNAPSHOT"
  :description "Some great description"

  :global-vars {*warn-on-reflection* true}

  :dependencies [[org.clojure/clojure "1.10.1"]
                 [fierycod/holy-lambda "0.0.6"]]
  :uberjar-name "output.jar"
  :aot :all)
