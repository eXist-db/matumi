xquery version "1.0";

declare variable $local:CREDENTIALS := ("admin", "");

if ($exist:resource eq 'search.xql') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="search.xql">
         </forward>
     </dispatch>
else if ($exist:resource eq 'annotate.xql') then
    if (request:get-parameter("action", ())) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="store.xql">
                <set-attribute name="xquery.user" value="{$local:CREDENTIALS[1]}"/>
                <set-attribute name="xquery.password" value="{$local:CREDENTIALS[2]}"/>
                <set-attribute name="xquery.attribute" value="data"/>
            </forward>
            <view>
                <forward url="annotate.xql">
                    <clear-attribute name="xquery.attribute"/>
                 </forward>
             </view>
        	<cache-control cache="no"/>
        </dispatch>
    else
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="annotate.xql">
                <clear-attribute name="xquery.attribute"/>
             </forward>
         </dispatch>
else if ($exist:path = "/") then
    if (request:get-parameter("action", ())) then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="store.xql">
                <set-attribute name="xquery.user" value="{$local:CREDENTIALS[1]}"/>
                <set-attribute name="xquery.password" value="{$local:CREDENTIALS[2]}"/>
                <set-attribute name="xquery.attribute" value="data"/>
            </forward>
            <view>
                <forward url="view.xql">
                    <clear-attribute name="xquery.attribute"/>
                 </forward>
             </view>
        	<cache-control cache="no"/>
        </dispatch>
    else
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <forward url="view.xql">
                <clear-attribute name="xquery.attribute"/>
             </forward>
         </dispatch>
         
(: paths starting with /libs/ will be loaded from the webapp directory on the file system :)
else if (starts-with($exist:path, "/libs/")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="/{substring-after($exist:path, 'libs/')}" absolute="yes"/>
    </dispatch>
    
else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <set-attribute name="xquery.user" value="{$local:CREDENTIALS[1]}"/>,
        <set-attribute name="xquery.password" value="{$local:CREDENTIALS[2]}"/>
        <cache-control cache="yes"/>
    </dispatch>