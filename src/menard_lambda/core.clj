(ns menard-lambda.core
  (:gen-class)
  (:require
    [fierycod.holy-lambda.core :as h]
    [menard.nederlands :as nl]))

(defn myfunction [q]
  (->> (-> q nl/parse)
       (map menard.nederlands/syntax-tree)
       (clojure.string/join ",")))

(h/deflambda ExampleLambda
  [event context]
  (h/info "Logging...")
  (h/info (str "THE Q PARAM: " (-> event :queryStringParameters :q)))
  (let [q (-> event :queryStringParameters :q)]
    {:statusCode 200
     :body (str "Hello world " (myfunction q) "!")
     :isBase64Encoded false}))

(h/gen-main [#'ExampleLambda])
