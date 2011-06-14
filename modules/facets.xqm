xquery version "1.0";

module namespace facet="http://exist-db.org/xquery/fasets";

declare namespace tei="http://www.tei-c.org/ns/1.0";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function facet:capitalize-first($str as xs:string) as xs:string {
    concat(upper-case(substring($str,1,1)), substring($str,2))
};

declare function facet:single(
    $root as element()?, 
    $type as xs:string?,
    $active-facets as xs:string*
 ) {
    <div class="facet">
        <h3 class="{$type}">{facet:capitalize-first($type)}</h3>
        <ul>{
            let $names :=
                distinct-values(
                    for $name in $root//tei:name[@type = $type]
                    return
                        $name/@key
                )
            for $name in $names order by $name
            return
                <li>
                    <input type="checkbox" name="facet" class="facet-check" value="{$name}"
                        title="Mark to restrict search"
                        dbURL="{$name}" >
                        {if (exists(index-of($active-facets, $name))) then attribute checked { "checked" } else ()}
                    </input>
                    <span>{translate(replace($name, "^.*/([^/]+)", "$1"), "_", " ")}</span>
                </li>
        }</ul>
    </div>
};

declare function facet:all( 
    $resource as xs:string?, 
    $node-id as x:strinng?,
    $active-facets as xs:string*      
 ){
    let $doc := if( exists($resource)) then  doc($resource) else ()

    return
    <div id="facets"> {
        for $facet in distinct-values($doc//tei:name/@type)
        order by $facet
        return facet:single($doc, $facet, $active-facets )
    }</div>
};

