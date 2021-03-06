module namespace func="http://exist-db.org/encyclopedia/functions";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";

declare function func:expand-name($context as node()*, $name as xs:string) {
    (:let $keys := collection($config:app-root)//rdf:Description[ft:query(rdfs:label, $name)]/@rdf:about:)
    let $keys := collection($config:app-root)//rdf:Description[rdfs:label eq $name]/@rdf:about
    (:let $log := util:log("DEBUG", ("##$keys: ", string-join($keys, " "))):) 
    let $keys := 
        if ($keys) then $keys 
        else collection($config:app-root)//rdf:Description[ft:query(rdfs:label, $name)]/@rdf:about
    for $key in $keys
    let $names := $context//tei:name[@key = $key]
    for $name in $names
    let $matched :=
        ngram:add-match($name)
    return
        $matched
};

declare function func:find-by-key($context as node()*, $key as xs:string) {
    let $matches := $context//*[@key = $key]
    for $match in $matches
    return
        ngram:add-match($match)
};