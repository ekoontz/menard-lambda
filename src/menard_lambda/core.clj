(ns menard-lambda.core
  (:gen-class)
  (:require
   [clojure.data.json :as json :refer [write-str]]
   [dag_unify.core :as u]
   [fierycod.holy-lambda.core :as h]
   [menard-lambda.handlers
    :refer [generate-by-spec
            generate-with-alternations
            parse-nl]]))

(h/deflambda ParseNL
  [event context]
  (h/info "Logging...")
  (let [q (-> event :queryStringParameters :q)]
    {:statusCode 200
     :headers {"Content-Type" "application/json"
               "Access-Control-Allow-Origin" "http://localhost.hiro-tan.org:3449"
               "Access-Control-Allow-Credentials" "true"}
     :body (-> q parse-nl)
     :isBase64Encoded false}))

(h/deflambda GenerateNL
  [event context]
  (h/info "Logging...")
  (let [q (-> event :queryStringParameters :q)]
    {:statusCode 200
     :headers {"Content-Type" "application/json"
               "Access-Control-Allow-Origin" "http://localhost.hiro-tan.org:3449"
               "Access-Control-Allow-Credentials" "true"}
     :body (-> q generate-by-spec)
     :isBase64Encoded false}))

(h/deflambda GenerateWithAltsNL
  [event context]
  (h/info "Logging...")
  (let [spec (-> event :queryStringParameters :spec)
        alternates (-> event :queryStringParameters :alts)]
    {:statusCode 200
     :headers {"Content-Type" "application/json"
               "Access-Control-Allow-Origin" "http://localhost.hiro-tan.org:3449"
               "Access-Control-Allow-Credentials" "true"}
     :body (generate-with-alternations spec alternates)
     :isBase64Encoded false}))

(h/gen-main [#'ParseNL])
