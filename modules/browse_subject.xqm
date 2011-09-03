xquery version "1.0";

module namespace browse-subject="http://exist-db.org/xquery/apps/matumi/browse-subject";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

import module namespace browse-data="http://exist-db.org/xquery/apps/matumi/browse-data" at "browse_data.xqm";



declare function local:capitalize-first($str as xs:string) as xs:string {
    concat(upper-case(substring($str,1,1)), substring($str,2))
 };

declare function browse-subject:titles-list-fast( $QUERIEs as element(query)*,  $level as node()?, $URIs as node()*, $Categories as element(category)*, $SUBJECTs as node()*  ){
    let $nodes := browse-data:execute-query( $QUERIEs[@name= $level ] ) 
    
    return  element titles {
        attribute {'name'}{ 'subject' },
        attribute {'count'}{ count($nodes)},
        attribute {'title'}{ $level/@title },
        element {'group'}{            
            for $n in fn:distinct-values( $nodes/@subtype ) 
             let $title := $n
             order by string($title)
             return 
                element {'title'} {
                     if( $n = $SUBJECTs  ) then attribute {'selected'}{'true'} else (),
                     attribute {'value'} {  $title  },  
                     local:capitalize-first( $title ),
                     concat(' (', count(  $nodes/@subtype[ . = $n ]), ')')                    
                }
       }
    }    
};
