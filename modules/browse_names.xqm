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
import module namespace browse-data="http://exist-db.org/xquery/apps/matumi/browse-data" at "browse_data.xqm";

declare function browse-names:titles-list-fast( 
    $QUERIEs as element(query)*,  
    $level as node()?, 
    $URIs as node()*, 
    $Categories as element(category)*
){
    let $Q := $QUERIEs[@name= $level ],
(:        $nodes := util:eval($data-all[1])  :)
    
       $start :=  dateTime(current-date(), util:system-time() ), 
       $categories :=  browse-summary:get-out-of-entries-only( $QUERIEs, $level, $URIs,  $Categories ),
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

declare function browse-names:entiry-categories-listed( $e as node(), $cat as node()*  ){
    let $categories :=  if( fn:exists($cat) ) then 
                             $cat
                        else browse-summary:get-one( $e )

    return if( exists($categories)) then (        
        <span class="cat-toggle collapsed">&#160;</span>,
        for $c at $cat-pos in $categories
          return (
               if( $cat-pos > 1 ) then <br class="br"/> else (),
               <span class="cat-name" title="{ concat( $c/@values, ' unique keys and ', $c/@instances, ' instaces'   ) }">{ concat( $c/@name, '(', $c/@values,'/', $c/@instances ,')')  } </span>,
               <span class="values">: {
                 for $n at $pos in $c/value 
                 let $title := concat( $n/@instances,' instances of "', $n, '"in this document')
                 return(
                     <a title="{$title} { if($n/@key = 'missing') then ' - Missing Key.' else ()}" class="cat-value-deep-link" 
                        href="{ concat('entry.html?doc=', document-uri( root($e)), 
                                        '&amp;node=',util:node-id($e), 
                                        '&amp;name-node-id=', $n/@name-node-id,
                                        '&amp;key=', $n/@key
                                      )}">{ 
                        string($n),        				            
                        if( number($n/@instances) > 1 ) then concat('(', $n/@instances,')') else ()	           
                     }</a>,
                     if( $pos < number($c/@values )) then ', ' else ()
                )
               }</span>
         )
     ) else(
         <span>-</span>
     )   
};

