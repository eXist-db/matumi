xquery version "1.0";

module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

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


declare function browse-names:extract-categories( $n as element()? ){ 
   let $categories := $n//tei:name[@type]
   let $types :=  distinct-values($categories/@type) 
   
   return 
        for $t in $types 
        let $values := $categories[@type = $t ], 
            $keys := distinct-values($values/@key)
                        
        order by $t
        return                    
            element category {               
               attribute {'name'}{$t},
               attribute {'count'}{ count( $keys ) },
               attribute {'total'}{ count( $values ) },
               for $k in $keys 
               let $instances := $values[@key = $k]
               let $first := $instances[1]                
               order by string( $k )
               return element {'name'}{ 
                    attribute {'key'}{ $k },
                    attribute {'count'}{ count($instances) },
                    attribute {'name-node-id'}{ util:node-id($first)},
                    string( $first )                    
               } 
            } 
};


declare function browse-names:titles-list( $nodes as element()*,  $level as node()? ){
    let $types := distinct-values($nodes/@type)    
    
    return element titles {
        attribute {'name'}{ 'name-type' },
        attribute {'count'}{ count($types)},
        attribute {'title'}{ $level/@title },            
   
        for $t in $types 
        let $n := $nodes[@type = $t ],
            $values := distinct-values($n/@key),
            $count := count( $n ),
            $total := count($values)
        order by $t
        return                    
            element title {               
               attribute {'name-type'}{$t},
               attribute {'count'}{$count},
                    if( $count > 1 ) then (
                       attribute {'title'}{ concat(  $total, ' unique keys and ', $count, ' instaces'   )},
                       concat( $t, ' (', $total, '/', $count ,')' )
                    )else $t
            } 

    }    
};

