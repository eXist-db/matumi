xquery version "1.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";

declare variable $server := "http://dbpedia.org/data/";
declare variable $tei-location := "/db/resources/commons/encyclopedias";

declare function local:target() {
    let $root := collection($tei-location)/rdf:RDF
    return
        if ($root) then 
            $root
        else
            let $doc := xmldb:store($tei-location, "labels.xml", <rdf:RDF/>)
            return
                doc($doc)/rdf:RDF
};

declare function local:retrieve($url as xs:string) {
    let $key := replace($url, "^.*/([^/]+)$", "$1")
    (:let $log := util:log("DEBUG", ("Retrieving ", $key, "...")):)
    let $uri := xs:anyURI(concat($server, $key, ".rdf"))
    let $rdf:= util:catch("*", httpclient:get($uri, false(), ()), util:log("WARN", ("Failed to load ", $uri))) 
    let $target := local:target()
    return
        update insert
            <rdf:Description rdf:about="{$url}">
            { $rdf//rdfs:label }
            </rdf:Description>
        into $target
};

for $node at $pos in collection($tei-location)//tei:name
let $key := $node/@key
where $key and empty(collection($tei-location)//rdf:Description[@rdf:about = $key])
return
    local:retrieve($key)