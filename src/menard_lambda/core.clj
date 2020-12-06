(ns menard-lambda.core
  (:gen-class)
  (:require
   [clojure.data.json :as json :refer [write-str]]
   [fierycod.holy-lambda.core :as h]
   [menard.english :as en]
   [menard.nederlands :as nl]
   [menard.translate :as tr]))

(defn parse-nl [string-to-parse]
  (h/debug (str "parsing input: " string-to-parse))
  (let [parses (->> string-to-parse
                    clojure.string/lower-case
                    nl/parse
                    (filter #(or (= [] (u/get-in % [:subcat]))
                                 (= :top (u/get-in % [:subcat]))
                                 (= ::none (u/get-in % [:subcat] ::none))))
                    (filter #(= nil (u/get-in % [:mod] nil)))
                    (sort (fn [a b] (> (count (str a)) (count (str b))))))
        syntax-trees (->> parses (map nl/syntax-tree))
        english (-> (->> parses
                         (map tr/nl-to-en-spec)
                         (map #(generate-english %
                                                 (clojure.string/join "," (map nl/syntax-tree parses))))
                         (map #(en/morph %))))]
    (log/info (str "nl: '" string-to-parse "' -> ["
                   (clojure.string/join "," english) "]"))
    {:nederlands string-to-parse
     :trees syntax-trees
     :english (first english)
     :sem (->> parses
               (map #(u/get-in % [:sem]))
               (map dag-to-string))})))

(h/deflambda ExampleLambda
  [event context]
  (h/info "Logging...")
  (h/info (str "THE Q PARAM: " (-> event :queryStringParameters :q)))
  (let [q (-> event :queryStringParameters :q)]
    {:statusCode 200
     :headers {"Content-Type" "application/json"}
     :body (-> q parse-nl write-str)
     :isBase64Encoded false}))

(h/gen-main [#'ExampleLambda])
