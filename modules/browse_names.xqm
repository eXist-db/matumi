xquery version "1.0";

module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";


declare function browse-names:data( $context-nodes as node()*, $URIs as node()*, $level-pos as xs:int ){ 
   let $name-types := request:get-parameter("name-type", () )
   return if( $level-pos = 1 ) then (
           if(exists( $name-types )) then 
                 collection(concat($config:app-root, '/data'))//tei:name[@type = $name-types]
           else  collection(concat($config:app-root, '/data'))//tei:name[@type]
        
    )else (
          if(exists( $name-types )) then 
               $context-nodes//tei:name[@type = $name-types]
          else $context-nodes//tei:name[@type] 
    )
};

declare function browse-names:titles-list( $nodes as element()*,  $level as node()? ){
    let $types := distinct-values($nodes/@type)    
    
    return element titles {
        attribute {'count'}{ count($types)},
        attribute {'title'}{ $level/@title },            
   
        for $t in $types 
        let $count := count( $nodes[@type = $t ])
        order by $t
        return                    
            element title {               
               attribute {'name-type'}{$t},
               attribute {'count'}{$count},
               concat( $t, ' (', $count, ')' )
            } 

    }    
};

