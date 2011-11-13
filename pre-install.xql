xquery version "1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";

declare variable $home external;
declare variable $dir external;
declare variable $target external;

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

util:log("INFO", ("Running pre-install script ...")),
if (xdb:group-exists($config:group)) then ()
else xdb:create-group($config:group),
if (xdb:exists-user($config:credentials[1])) then ()
else xdb:create-user($config:credentials[1], $config:credentials[2], $config:group, ()),

util:log("INFO", ("Loading collection configuration ...")),
local:mkcol("/db/system/config", $target),
xdb:store-files-from-pattern(concat("/db/system/config/", $target), $dir, "*.xconf")
