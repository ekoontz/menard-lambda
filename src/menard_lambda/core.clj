(ns menard-lambda.core
  (:gen-class)
  (:require
    [fierycod.holy-lambda.core :as h]
    [menard.nederlands :as nl]))

(defn myfunction []
  (->> (-> "een aardig bedroefd buitengewoon afzonderlijk dik nieuwswaardig ongerust teleurgesteld eigenwijs geheim verrast prachtig slim vrouw probeert mannen te zien"
           nl/parse)
       (map menard.nederlands/syntax-tree)
       (clojure.string/join ",")))

(h/deflambda ExampleLambda
  [event context]
  {:statusCode 200
   :body (str "Hello world " (myfunction) "!")
   :isBase64Encoded false})

(h/gen-main [#'ExampleLambda])
