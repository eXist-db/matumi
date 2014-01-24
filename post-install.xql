xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";

declare variable $home external;
declare variable $dir external;
declare variable $target external;

declare function local:chmod-recursive($collection, $mode) {
    for $resource in xmldb:get-child-resources($collection)
    return
        xmldb:chmod-resource($collection, $resource, $mode),
    for $child in xmldb:get-child-collections($collection)
    return
        local:chmod-recursive(concat($collection, "/", $child), $mode)
};

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

util:log("INFO", ("Running post-install script ...")),

local:mkcol($target, 'cache'),
xdb:set-collection-permissions( concat($target,'/cache'), $config:credentials[1], $config:group,  xmldb:string-to-permissions('rwxrwxrwx') ),
local:chmod-recursive($config:data-collection, xmldb:string-to-permissions("rwxrwxr--")),

xmldb:remove($target || "/" || "Encyclopedias"),
xmldb:remove($target || "/" || "images")
