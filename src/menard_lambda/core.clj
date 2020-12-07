(ns menard-lambda.core
  (:gen-class)
  (:require
   [clojure.data.json :as json :refer [write-str]]
   [dag_unify.core :as u]
   [fierycod.holy-lambda.core :as h]
   [menard.english :as en]
   [menard.nederlands :as nl]
   [menard.translate :as tr]))

(defn generate-english [spec nl]
  (let [result (->> (repeatedly #(-> spec
                                     en/generate))
                    (take 2)
                    (filter #(not (nil? %)))
                    first)]
    (when (nil? result)
      (h/warn (str "failed to generate on two occasions with nl: '" nl "'")))
    result))

(defn dag-to-string [dag]
  (-> dag dag_unify.serialization/serialize str))

(defn parse-nl [string-to-parse]
  (h/info (str "parsing input: " string-to-parse))
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
    (h/info (str "nl: '" string-to-parse "' -> ["
                   (clojure.string/join "," english) "]"))
    {:nederlands string-to-parse
     :trees syntax-trees
     :english (first english)
     :sem (->> parses
               (map #(u/get-in % [:sem]))
               (map dag-to-string))}))

(h/deflambda ParseNL
  [event context]
  (h/info "Logging...")
  (h/info (str "THE Q PARAM: " (-> event :queryStringParameters :q)))
  (let [q (-> event :queryStringParameters :q)]
    {:statusCode 200
     :headers {"Content-Type" "application/json"}
     :body (-> q parse-nl)
     :isBase64Encoded false}))

(h/gen-main [#'ParseNL])
