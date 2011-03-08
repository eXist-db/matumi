xquery version "1.0";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:key($key, $options) {
    concat('"', $key, '"')
};

declare function local:qnames($field as xs:string?) {
    if ($field eq 'Lemma') then
        (xs:QName("tei:term"), xs:QName("tei:orth"))
    else if ($field eq 'Name') then
        xs:QName("tei:name")
    else
        xs:QName("tei:term")
};

let $term := request:get-parameter("term", ())
let $field := request:get-parameter("field", ())
let $qnames := local:qnames($field)
let $callback := util:function(xs:QName("local:key"), 2)
return
    concat("[",
        string-join(
            util:index-keys-by-qname($qnames, $term, $callback, 20, "lucene-index"),
            ', '
        ),
        "]")