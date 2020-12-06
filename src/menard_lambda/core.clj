(ns menard-lambda.core
  (:gen-class)
  (:require
    [fierycod.holy-lambda.core :as h]))

(h/deflambda ExampleLambda
  [event context]
  {:statusCode 200
   :body "Hello world!"
   :isBase64Encoded false})

(h/gen-main [#'ExampleLambda])
