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

declare function  browse-names:categories-number($n as element()* ){   
   count( $n/descendant-or-self::tei:name[@type])
};

declare function browse-names:categories-list( $n as element()*, $add-node-id as xs:boolean ) {
    for $name in $n/descendant-or-self::tei:name[@type][@key]
    group $name as $byType by $name/@type as $type
    return
        let $values :=
            for $name in $byType
            group $name as $byKey by $name/@key as $key
            return
                   let $instances-count := count($byKey)
                   let $keyName := translate(replace($key, "^.*/([^/]+)$", "$1"), "_", " ")
                   return element {'value'}{ 
                        attribute {'key'}{ $key },
                        attribute {'count'}{ $instances-count },
                        attribute {'name-node-id'}{ util:node-id($byKey[1])},
                        fn:string-join((
                               $keyName
                               (: , if( $instances-count > 1 ) then (' (', $instances-count , ')') else ()  :)
                            ),'')                                        
                   }
        return
            element category {               
                   attribute {'name'}{$type},
                   attribute {'count'}{ count($values) },
                   $values
            }
};

(:
declare function browse-names:categories-list( $n as element()*, $add-node-id as xs:boolean ) { 
   let $categories := $n/descendant-or-self::tei:name[@type]
   let $types :=  distinct-values($categories/@type)
   let $allKeys := distinct-values($categories/@key)
   return 
        for $t in $types
        let $this-cat-values := $categories[@type = $t ], 
            $keys := distinct-values($this-cat-values/@key)
        order by $t
        return                    
            element category {               
               attribute {'name'}{$t},
               attribute {'count'}{ count( $keys ) },
               attribute {'total'}{ count( $this-cat-values ) },
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
                            ),'')                                        
                   }           
            } 
};
:)

declare function browse-names:titles-list( 
    $nodes as element()*,  
    $level as node()?, 
    $URIs as node()*, 
    $Categories as element(category)*  
 ){
     let $categories := browse-names:categories-list( $nodes, false() ) (: false to prevent long initial caching :)
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



(: to do: move saving of the categories to browse-names:categories-list  :)

declare function browse-names:entiry-categories-listed( $e as node(), $save-categories as xs:boolean ){
    let $categories :=  if( exists( $e/categories-summary ) and not($browse:refresh-categories) ) then (
         $e/categories-summary/*
    ) else ( 
        let $c := browse-names:categories-list($e, false())
        let $save := if( $browse:save-categories ) then 
            util:catch("*", (
                  update insert element {'categories-summary'}{ $c } into $e 
               ), (
                 (: 
                   util:log("WARN", ("Failed to save categories summary for ", concat( document-uri( root($e)), util:node-id($e)) ))
                 :)
               ) 
            )
           else ()
        return $c
    ) 
    
    return
        for $c in $categories
        let $total := sum($c/value/@count)
        return
            <div>
               <span class="cat-name">{ 
                    attribute {'title'}{ concat(  $c/@count, ' unique keys and ', $total, ' instaces'   )},
                    string($c/@name),
                    concat('(', $c/@count,'/', $total ,')')				            
               }:</span>
               {
                 for $n at $pos in $c/value 
                 let $title := concat( $n/@count,' instances in this document')
                 return(
                 <a title="{$title} {if($n/@key = 'missing') then ' - Missing Key!' else ()}" class="cat-value-deep-link" 
                    href="{ concat('entry.html?doc=', document-uri( root($e)), 
                                    '&amp;node=',util:node-id($e), 
                                    '&amp;name-node-id=', $n/@name-node-id,
                                    '&amp;key=', $n/@key
                                  )}">{ 
                    string($n),        				            
                    if( number($n/@count) > 1 ) then concat('(', $n/@count,')') else ()	           
                 }</a>,
                 if( $pos < number($c/@count)) then ', ' else ()
                )
               }
            </div>    
};

