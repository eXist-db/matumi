xquery version "1.0";

import module namespace theme="http:/exist-db.org/xquery/matumi/theme" at "modules/theme.xqm";

declare variable $local:CREDENTIALS := ("admin", "");

declare variable $exist:resource external;
declare variable $exist:path external;
declare variable $exist:root external;
declare variable $exist:prefix external;
declare variable $exist:controller external;
declare variable $local:controller-url := concat( fn:substring-before(request:get-url(), $exist:controller),$exist:controller);

if ($exist:path eq "/") then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="browse.html"/>
    </dispatch>
    
else if ($exist:resource eq 'browse-section') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="modules/browse-section.xql">
            <add-parameter name="controller-url" value="{$local:controller-url}"/>        
        </forward>
     </dispatch>
    
else if ($exist:resource eq 'search.xql') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="modules/search.xql">
         </forward>
     </dispatch>
else if ($exist:resource eq 'annotate.xql') then
    if (request:get-parameter("action", ())) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="modules/store.xql">
                <set-attribute name="xquery.attribute" value="data"/>
            </forward>
            <view>
                <forward url="modules/annotate.xql">
                    <clear-attribute name="xquery.attribute"/>
                 </forward>
             </view>
        	<cache-control cache="no"/>
        </dispatch>
    else
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="modules/annotate.xql">
                <clear-attribute name="xquery.attribute"/>
             </forward>
         </dispatch>         
else if (ends-with($exist:path, ".html")) then
    if (request:get-parameter("action", ()) = "store") then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="modules/store.xql">
                <set-attribute name="xquery.attribute" value="data"/>
            </forward>
            <view>
                <forward url="modules/view.xql">
                    <clear-attribute name="xquery.attribute"/>
                 </forward>
             </view>
        	<cache-control cache="no"/>
        </dispatch>
    else
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="{theme:resolve($exist:prefix, $exist:root, $exist:resource)}"/>
            <view>
                <forward url="modules/view2.xql">
                
                    <set-attribute name="exist:prefix" value="{$exist:prefix}"/>
                    <set-attribute name="exist:root" value="{$exist:root}"/>
                    <clear-attribute name="xquery.attribute"/>
                    <add-parameter name="controller-url" value="{$local:controller-url}"/>
                    <add-parameter name="resource" value="{$exist:resource}"/>                    
                 </forward>
            </view>
         </dispatch>
         
(: paths starting with /libs/ will be loaded from the webapp directory on the file system :)
else if (starts-with($exist:path, "/libs/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/{substring-after($exist:path, 'libs/')}" absolute="yes"/>
    </dispatch>

else if (starts-with($exist:path, "/theme")) then
let $path := theme:resolve($exist:prefix, $exist:root, substring-after($exist:path, "/theme"))
let $themePath := replace($path, "^(.*)/[^/]+$", "$1")
return
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$path}">
            <set-attribute name="theme-collection" value="{theme:get-path()}"/>
        </forward>
    </dispatch>

else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <add-parameter name="controller-url" value="{$local:controller-url}"/>      
        <cache-control cache="yes"/>
    </dispatch>