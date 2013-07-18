xquery version "1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace config="http://exist-db.org/xquery/apps/config" at "modules/config.xqm";

declare variable $home external;
declare variable $dir external;
declare variable $target external;

declare variable $log-level := "INFO";
declare variable $db-root := "/db";
declare variable $config-collection := fn:concat($db-root, "/system/config");

(:~ Biblio security - admin user and users group :)
declare variable $biblio-admin-user := "editor";
declare variable $biblio-users-group := "biblio.users";

(:~ Collection paths :)
declare variable $app-collection := $target;
declare variable $resources-collection-name := "resources";
declare variable $resources-collection := fn:concat($db-root, "/", $resources-collection-name);
declare variable $commons-collection-name := "commons";
declare variable $commons-collection := fn:concat($resources-collection, "/", $commons-collection-name);
declare variable $data-collection-name := "encyclopedias";
declare variable $data-collection := fn:concat($commons-collection, "/", $data-collection-name);
declare variable $image-collection-name := "images/EncBrit";
declare variable $image-collection := fn:concat($commons-collection, "/", $data-collection-name, "/", $image-collection-name);

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

declare function local:set-collection-resource-permissions($collection as xs:string, $owner as xs:string, $group as xs:string, $permissions as xs:int) {
    for $resource in xdb:get-child-resources($collection) return
        xdb:set-resource-permissions($collection, $resource, $owner, $group, $permissions)
};

declare function local:strip-prefix($str as xs:string, $prefix as xs:string) as xs:string? {
    fn:replace($str, $prefix, "")
};

util:log("INFO", ("Running pre-install script ...")),

(: Create users and groups :)
util:log($log-level, fn:concat("Security: Creating user '", $biblio-admin-user, "' and group '", $biblio-users-group, "' ...")),
if (xdb:group-exists($config:group)) then ()
else xdb:create-group($config:group),
if (xdb:exists-user($config:credentials[1])) then ()
else xdb:create-user($config:credentials[1], $config:credentials[2], $config:group, ()),
util:log($log-level, "Security: Done."),

(: Load collection.xconf documents :)
util:log("INFO", ("Loading collection configuration ...")),
local:mkcol($config-collection, $resources-collection),
xdb:store-files-from-pattern(concat($config-collection, $resources-collection), concat($dir, '/xconf/resources'), "*.xconf"),
local:mkcol($config-collection, $app-collection),
xdb:store-files-from-pattern(concat($config-collection, $app-collection), concat($dir, '/xconf/matumi'), "*.xconf"),

(: Create data collection and upload sample data:)
util:log($log-level, fn:concat("Config: Creating commons collection '", $commons-collection, "'...")),
local:mkcol($db-root, local:strip-prefix($data-collection, fn:concat($db-root, "/"))),
xdb:store-files-from-pattern($data-collection, concat($dir, '/', $data-collection-name), "*.xml"),
local:mkcol($db-root, local:strip-prefix($image-collection, fn:concat($db-root, "/"))),
xdb:store-files-from-pattern($image-collection, concat($dir, '/', $image-collection-name), "*.png"),

util:log($log-level, "Config: Done."), 

util:log($log-level, "Script: Done.")
