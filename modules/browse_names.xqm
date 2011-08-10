xquery version "1.0";

module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;


import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";

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



(:
declare function browse-names:categories-summary-all( $context-nodes as node()*, $root as xs:boolean){   
   if( $root and false()) then 
        browse-names:all-categories-summary(  $browse:refresh-categories )
   else (
       let $result := for $n in $context-nodes 
          return typeswitch ( $n )
                case element(tei:TEI) return browse-names:categories-summary-get( $n, $browse:refresh-categories)        
                case element(tei:div) return browse-names:categories-summary-get( $n, $browse:refresh-categories)
                default return 
                     <category name="error" count="1" total="1">
                         <value key="none" count="1" >browse-names:categories-summary-all expects only context nodes tei:TEI and tei:div </value>
                     </category>
      return 
         if( count($context-nodes) > 1 ) then 
            browse-names:categories-summary-combine( $result )     
         else $result
   )
};   
:)

declare function browse-names:categories-summary-get( $nodes as node()*, $level as element(level), $Categories as element(category)*, $update as xs:boolean ){
  if( $level/@pos = 1 ) then( 
      let   $uri :=  concat($config:app-root, '/cache/all-categories-summary.xml'),
            $saved-summary := if( fn:doc-available($uri) ) then doc($uri)/*  else ()
            
      return  if( exists( $saved-summary ) and not($update) ) then 
                   $saved-summary//category 
              else(
                let $new-summary := browse-names:categories-list( browse-names:data-all((),(),true()), false() ),
                    $saved := browse-names:categories-summary-save( (), $new-summary, $browse:refresh-categories, $browse:embeded-category-summary  ) 
                return $new-summary
            )
   )else (
    
    let $existing-summary := if( $browse:refresh-categories) then () else collection( concat($config:app-root, '/cache'))/categories-summary[ @uuid = $nodes/@uuid ],
        $nodes-with-missing-summary  := if( $browse:refresh-categories) then $nodes else $nodes[ not(@uuid)],
        $fresh := for $n at $pos in $nodes-with-missing-summary[ position() <= $browse:max-cat-summary-to-save ] return  
                       let $new-summary := browse-names:categories-list($n, false() ),                        
                        $save := if( local-name($n) = ('TEI','div') and (  $browse:save-categories or $update ) and $pos < $browse:max-cat-summary-to-save ) then 
                                     browse-names:categories-summary-save( $n, $new-summary,  $browse:refresh-categories,  $browse:embeded-category-summary ) (:   util:eval-async(   :)
                                 else ()                                
                    return $new-summary
    let $result := (
        $existing-summary,
        $fresh, 
        browse-names:categories-list( fn:subsequence($nodes-with-missing-summary, $browse:max-cat-summary-to-save+1 ), false() )
      )  
  (:      for $n at $pos in $missing-summary return 
           let $saved-summary :=  $n/categories-summary       
           return if( fn:exists($saved-summary) and not($update) and not($browse:refresh-categories )) then ( 
                     $saved-summary/*
                ) else (                     
                    let $new-summary := browse-names:categories-list($n, false() ),                        
                        $save := if( local-name($n) = ('TEI','div') and (  $browse:save-categories or $update ) and $pos < $browse:max-cat-summary-to-save ) then 
                                     browse-names:categories-summary-save( $n, $new-summary,  $browse:refresh-categories,  $browse:embeded-category-summary ) (:   util:eval-async(   :)
                                 else ()                                
                    return $new-summary
                )
       )
:)       
     return 
       if( count( $nodes ) > 1 ) then (
           browse-names:categories-summary-combine( $result, $Categories )
       )else $result
  )
};

declare function browse-names:categories-summary-combine( $categories as element(category)*, $Categories as element(category)* ){
     for $name in fn:distinct-values( $categories/@name )
       let $nodes-of-this-type := $categories[@name= $name],
           $keys := fn:distinct-values($nodes-of-this-type//@key)
       order by fn:lower-case($name) 
       return    
          if( fn:count( $nodes-of-this-type) = 1 ) then
             $nodes-of-this-type
          else(
         
             element {'category'}{
                 attribute {'name'}{ $name },
                 attribute {'count'}{ count($keys) },
                 attribute {'values'}{ sum( $nodes-of-this-type/value/@count) },
                
                 for $k in $keys
                   let $values := $nodes-of-this-type/value[@key = $k]
                   return (
                     if( fn:count( $values ) = 1 ) then
                         $values
                     else 
                    
                     element {'value'}{
                        attribute {'key'}{ $k },
                        attribute {'count'}{ sum( $values/@count) },
                        $values[1]/@value-insted-of-key,
                        string($values[1])
                     }
                 )
           }
     )
}; 

(:

    <category name="instituion" count="0" no-keys="1" total="1">
        <value key="Asiatic Society" value-insted-of-key="yes" count="1" name-node-id="3.2.2.2.4.4.8.128">Asiatic Society*</value>
    </category>

:)

declare function browse-names:categories-summary-save( $node as node()?, $categories as element(category)*,  $update as xs:boolean, $embeded as xs:boolean  ){
    
      let   $uuid := if( fn:exists( $node/@uuid )) then  $node/@uuid else util:uuid(),
            $existing-uuid :=  if( fn:empty($node/@uuid ) and fn:exists($node)) then 
                                        update insert  $uuid into $node  (:  Side effect  :)  
                                else ()  
            
      return if( not($embeded)) then ( 
          let $coll := concat($config:app-root, '/cache'),
              $file-name := if( fn:empty($node)) then 'all-categories-summary.xml' else concat($uuid, '.xml'),
              $uri := concat( $coll, '/', $file-name)

         return if( fn:doc-available($uri) and not($update)) then (
          )else(
              util:catch("*", (    
                xdb:store( $coll, $file-name ,  
                     element {'categories-summary'}{
                       attribute {'ts'}{ dateTime(current-date(), util:system-time() ) },
                       attribute {'uuid'}{$uuid },                    
                       $categories
                   } 
                 ),
                   util:log("INFO", ("Saved categories-summary for ", document-uri( root($node)), ', ', if( fn:exists($node)) then util:node-id( $node ) else() )  )
                ), util:log("WARN", ("Failed to save categories-summary for ", document-uri( root($node)), ', ',if( fn:exists($node)) then util:node-id( $node ) else() )  )
              )
          )          
      )else (  
          let $saved-summary := $node/tei:categories-summary,               
              $new-summary  := 
                   element {'categories-summary'}{
                       attribute {'ts'}{ dateTime(current-date(), util:system-time() ) },
                       attribute {'uuid'}{$uuid },                    
                       $categories
                   } 
                   
          return  util:catch("*", (                                   
                     if( fn:empty($saved-summary)) then
                         update insert $new-summary into $node 
                     else if( $update ) then  
                         update replace $saved-summary with $new-summary
                     else (),                    
                     util:log("INFO", ("Saved categories-summary for ", document-uri( root($node)), ', ', util:node-id( $node ))  )
                  ), util:log("WARN", ("Failed to save categories-summary for ", document-uri( root($node)), ', ', util:node-id( $node ))  )
                )                
   )
};

declare function  browse-names:categories-number($n as element()* ){   
   count( $n/descendant-or-self::tei:name[@type])
};

declare function browse-names:categories-list( $n as element()*, $add-node-id as xs:boolean ) {
   for $name in $n/descendant-or-self::tei:name[@type][@key]
    group $name as $byType by $name/@type as $type
   order by $type  
    return
        let $values :=
            for $name in $byType
            group $name as $byKey by $name/@key as $key
            order by fn:lower-case($key) 
            return
                   let $instances-count := count($byKey)
                   let $keyName := translate(replace($key, "^.*/([^/]+)$", "$1"), "_", " ")
                   return element {'value'}{ 
                        attribute {'key'}{ $key },
                        attribute {'count'}{ $instances-count },
                        if( $add-node-id ) then ( attribute {'name-node-id'}{ util:node-id($byKey[1])} ) else(),
                        fn:string-join((
                               $keyName
                               (: , if( $instances-count > 1 ) then (' (', $instances-count , ')') else ()  :)
                            ),'')                                        
                   }
        return
            element category {               
                   attribute {'name'}{$type},
                   attribute {'count'}{ count($values) },
                   attribute {'total'}{ sum($values/@count) },
                   $values
            }
};

declare function browse-names:titles-list( 
    $nodes as element()*,  
    $level as node()?, 
    $URIs as node()*, 
    $Categories as element(category)*  
 ){
     let $start :=  dateTime(current-date(), util:system-time() ), 
        $categories := browse-names:categories-summary-get($nodes, $level, $Categories, $browse:refresh-categories ),
                        
(:        
        if( $browse:LEVELS[1] = 'names' and fn:empty( $browse:URIs/uri)) then
               browse-names:all-categories-summary( $browse:refresh-categories )                               
        else 
                browse-names:categories-list( $nodes, $browse:refresh-categories ),
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



(: to do: move saving of the categories to browse-names:categories-list  :)

declare function browse-names:entiry-categories-listed( $e as node(), $save-categories as xs:boolean )
{
    (:
    browse-names:categories-summary-get( $nodes as node()*, $Categories as element(category)*, $root as xs:boolean,  $last as xs:boolean, $update as xs:boolean )
    :)
    let $categories :=  if( exists( $e/tei:categories-summary ) and not($browse:refresh-categories) ) then (
         $e/tei:categories-summary/*
    ) else ( 
        let $c := browse-names:categories-list($e, false())
        let $save := if( $browse:save-categories ) then 
            browse-names:categories-summary-save( $e, $c,  $browse:refresh-categories, $browse:embeded-category-summary )
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

