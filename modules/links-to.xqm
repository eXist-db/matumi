module namespace links-to="http://exist-db.org/xquery/apps/matumi/links-to";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xf="http://www.w3.org/TR/2002/WD-xquery-operators-20020816";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

declare function links-to:person( $node as element(person), $link-text as xs:string*) as element (a) {
    <a class="{$node/@role} role person" href="{ ($node/@key | $node/@ref )[1]}" target="_new">{
        if( fn:exists($node/xml:id) ) then attribute {'title'}{ $node/xml:id }else(),
        if( fn:exists($node/@xml:id) ) then attribute {'title'}{ $node/@xml:id }else(),
        $link-text 
    }</a>
};

declare function links-to:name( $node as element(name), $link-text as xs:string*) as element (a) {
     <a class="{$node/@type} name" href="{ ($node/@key | $node/@ref )[1]}" target="_new">{  
         if( fn:exists($node/@xml:id) ) then attribute {'title'}{ $node/@xml:id }else(),
         if( fn:exists($node/@exist:id) ) then attribute {'id'}{  $node/@exist:id }else(),
         $link-text 
     }</a>
};
