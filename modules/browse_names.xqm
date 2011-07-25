xquery version "1.0";

module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";

declare function browse-names:data-all( $context-nodes as node()*, $root as xs:boolean){
   if( $root ) then 
        collection(concat($config:app-root, '/data'))//tei:name[@type]       
   else $context-nodes//tei:name[@type] 
};   

declare function browse-names:data-filtered( $data as node()*, $URIs as node()*, $Categories as element(category)* ){       
    let $name-types := request:get-parameter("name-type", () )
    return  if(exists( $name-types )) then (
       $data//tei:name[@type = $name-types]
    )else   
        $data    
};

declare function browse-names:categories-list( $n as element()* ){ 
   let $categories := $n/descendant-or-self::tei:name[@type]
   let $types :=  distinct-values($categories/@type) 
 
   return 
        for $t in $types 
        let $this-cat-values := $categories[@type = $t ], 
            $keys := distinct-values($this-cat-values/@key),
            $no-keys := distinct-values($this-cat-values[empty(@key)])
                        
        order by $t
        return                    
            element category {               
               attribute {'name'}{$t},
               attribute {'count'}{ count( $keys ) },
               if( exists( $no-keys )) then attribute {'no-keys'}{ count($no-keys) } else (),               
               attribute {'total'}{ count( $this-cat-values ) },
               
               for $nk in $no-keys 
                   let $instances := $this-cat-values[. = $nk],                   
                       $instances-count := count($instances),
                       $key-value := fn:normalize-space(string( $instances[1] ))                      
                   order by string( $nk )
                   return element {'value'}{ 
                        attribute {'key'}{ $key-value },
                        attribute {'value-insted-of-key'}{ 'yes' },
                        attribute {'count'}{ $instances-count },
                        attribute {'name-node-id'}{ util:node-id($instances[1])},                        
                        fn:string-join((
                               $key-value,                               
                               if( $instances-count > 1 ) then (' (', $instances-count , ')') else (),
                               '*'
                            ),'')                                        
                   },
                   
               for $k in $keys 
                   let $instances := $this-cat-values[@key = $k],                   
                       $instances-count := count($instances)                    
                   order by string( $k )
                   return element {'value'}{ 
                        attribute {'key'}{ $k },   
                        attribute {'count'}{ $instances-count },
                        attribute {'name-node-id'}{ util:node-id($instances[1])},
                        fn:string-join((
                               fn:normalize-space(string( $instances[1] ))
                               (: , if( $instances-count > 1 ) then (' (', $instances-count , ')') else ()  :)
                            ),'')                                        
                   }           
            } 
};

declare function browse-names:titles-list( 
    $nodes as element()*,  
    $level as node()?, 
    $URIs as node()*, 
    $Categories as element(category)*  
 ){
     let $categories := browse-names:categories-list( $nodes)
     return element titles {
        attribute {'name'}{ 'category' }, (: combo name, ie the parameter name :)
        attribute {'count'}{ count( $categories )},
        attribute {'total'}{ count( $categories/* )},
        attribute {'title'}{ $level/@title },            
   
        for $c in $categories 
        let $c-selected := $Categories[ name = $c/@name and key = '*' ]
        return
        element {'group'}{
            $c/@count,
            $c/@total, 
            $c/@name,
            attribute {'title'}{ string($c/@name)},             
            element {'title'}{
                attribute {'value'}{$c/@name},
                $c/@*,
                if( exists($c-selected) ) then attribute {'selected'}{'true'} else (),
                concat( 'All ', $c/@count, ' values for category "', $c/@name, '"' )
            }, 
            for $t in $c/*  
            let $c-selected := if( exists( $t/@value-insted-of-key )) then            
                                    $Categories[  name = $c/@name and value = $t/@key  ]
                               else $Categories[  name = $c/@name and key = $t/@key ]
            return                    
                element title {
                    if( $c-selected  ) then attribute {'selected'}{'true'} else (),
                    $c/@count,
                    $c/@total,            
                    attribute {'value'}{ 
                        if( exists( $t/@value-insted-of-key )) then     
                             concat($c/@name, $browse:delimiter-uri-nameNode, $t/@key)
                        else concat($c/@name, $browse:delimiter-uri-node, $t/@key)
                      },
(:                   
                    if( number($c/@count) > 1 ) then (
                       attribute {'title'}{ concat(  $total, ' unique keys and ', $count, ' instaces'   )},
                       concat( $t, ' (', $total, '/', $count ,')' )
                    )else $t
:)                  string($t)  
                }
        }           

    }    
};
