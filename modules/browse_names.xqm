xquery version "1.0";

module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;


import module namespace util="http://exist-db.org/xquery/util";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
(: import module namespace browse-config="http://exist-db.org/xquery/apps/matumi/browse-config" at "browse_config.xqm"; :)
import module namespace browse-summary="http://exist-db.org/xquery/apps/matumi/browse-summary" at "browse_summary.xqm";

declare function browse-names:data-all( $context-nodes as node()*,  $level as node(), $root as xs:boolean){   
   if( $root  ) then 
        collection(concat($config:app-root, '/data'))//tei:name[@type]       
   else if( $level/@last ) then( 
        $context-nodes (: when this is the last level there is no need to extract names. entry or book nodes will be returned 
                          title-list will use the cached category lists :)
   )else $context-nodes//tei:name[@type]
}; 

declare function browse-names:data-filtered( $data as node()*,  $level as node(), $URIs as node()*, $Categories as element(category)* ){       
    if( $level/@last or empty( $Categories )) then 
        $data 
    else (
(:   todo distinguish entities from categories 
   <category name="event" count="1" total="1">
      <value key="http://dbpedia.org/page/Mukden_Incident" count="1">Mukden Incident</value>
   </category>
:)
    
            let $names-with-values := if( exists( $Categories/value) ) then 
                           for $n in $data/descendant-or-self::tei:name[  empty(@key) and @type =  $Categories/name ]
                           return if( exists( $Categories[ name = $n/@type and value = fn:normalize-space($n )  ])) then 
                                     $n
                                  else ()
                        else ()                
               
            return ( if( exists($Categories[key='*']) ) then (
                       $data[  ./descendant-or-self::tei:name[ @type = $Categories[key='*']/name ] ]
                    )else ())
                    |
                    (if( exists($Categories[ key != '*']) ) then
                       $data[  ./descendant-or-self::tei:name[ @key = $Categories/key[not(. = '*') ] ]]
                    else ())                       
                    | 
                   $names-with-values/ancestor-or-self::tei:div[@type="entry"]   

    )
};





declare function browse-names:titles-list( 
    $nodes as element()*,  
    $level as node()?, 
    $URIs as node()*, 
    $Categories as element(category)*  
 ){
     let $start :=  dateTime(current-date(), util:system-time() ), 
        $categories :=  browse-summary:get($nodes, $level/@pos = 1, $URIs,  $Categories, $browse:refresh-categories,  $browse:embeded-category-summary ),
                        
(:        
        if( $browse:LEVELS[1] = 'names' and fn:empty( $browse:URIs/uri)) then
               browse-names:all-categories-summary( $browse:refresh-categories )                               
        else 
                 browse-summary:list( $nodes, $browse:refresh-categories ),
  :)              
       $ts-categories-list :=  dateTime(current-date(), util:system-time() ) - $start,
       $ts-cat-start := dateTime(current-date(), util:system-time() ),
       $cat := for $c in $categories 
           let $c-selected := $Categories[ name = $c/@name and key = '*' ]
           
           return element {'group'}{
               $c/@count,
               $c/@values, 
               $c/@name,
               attribute {'title'}{ string($c/@name)},             
               if( count( $c/* ) > 1 ) then (            
                    element {'title'}{
                        attribute {'value'}{$c/@name},
                        $c/@*,
                        if( exists($c-selected) ) then attribute {'selected'}{'true'} else (),
                        concat( 'Any value for "', $c/@name, '"(',  $c/@count, ')' )
                    }
               ) else(),
               
               for $t in $c/*  
               let $t-selected := if( exists( $t/@value-insted-of-key )) then            
                                       $Categories[  name = $c/@name and value = $t/@key  ]
                                  else $Categories[  name = $c/@name and key = $t/@key ]
               return                    
                   element title {
                       if( $t-selected  ) then attribute {'selected'}{'true'} else (),
                       $t/@count,
                       $t/@total,            
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
           },
    $ts-cat-time :=  dateTime(current-date(), util:system-time() ) - $ts-cat-start
       
  return element titles {
        attribute {'name'}{ 'category' }, (: combo name, ie the parameter name :)
        attribute {'count'}{ count( $categories )},
        attribute {'total'}{ count( $categories/* )},
        attribute {'values'}{ sum( $categories//@values )},
        attribute {'title'}{ $level/@title },
        attribute {'time-categories-list'}{ $ts-categories-list }, 
        attribute {'time-categories-render'}{ $ts-cat-time },          
        $cat
    } 
};

declare function browse-names:categories-number($n as element()* ){   
   count( $n/descendant-or-self::tei:name[@type])
};
declare function browse-names:summary-detailes($n as element()* ){   
   browse-summary:detailes($n)     
};





(: to do: move saving of the categories to  browse-summary:list  :)

declare function browse-names:entiry-categories-listed( $e as node(), $refresh-categories as xs:boolean ){
    let $categories :=  browse-summary:get-one( $e )

    return if( exists($categories)) then (        
        <span class="cat-toggle collapsed">&#160;</span>,
        for $c at $cat-pos in $categories
          let $total := sum($c/value/@count)
          return (
               if( $cat-pos > 1 ) then <br class="br"/> else (),
               <span class="cat-name" title="{ concat(  $c/@count, ' unique keys and ', $total, ' instaces'   ) }">{ concat( $c/@name, '(', $c/@count,'/', $total ,')')  } </span>,
               <span class="values">: {
                 for $n at $pos in $c/value 
                 let $title := concat( $n/@count,' instances in this document')
                 return(
                     <a title="{$title} { if($n/@key = 'missing') then ' - Missing Key!' else ()}" class="cat-value-deep-link" 
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
               }</span>
         )
     ) else()   
};

