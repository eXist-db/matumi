xquery version "1.0";

module namespace browse-data="http://exist-db.org/xquery/apps/matumi/browse-data";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function browse-data:now() as xs:dateTime {   dateTime(current-date(), util:system-time() ) };


(:~
 : create file-node URI depending on the type of the element node.
 :)

(: example: local:change-element-ns-deep($x, "http://www.w3.org/1999/xhtml")  :)
declare function browse-data:change-element-ns-deep ($element as element(), $newns as xs:string) as element(){
  let $newName := QName($newns, local-name($element))
  return
  (element {$newName} {
    $element/@*, for $child in $element/node()
      return
        if ($child instance of element())
        then browse-data:change-element-ns-deep($child, $newns)
        else $child
  })
};

(:
    It is all about selecting a subset of entries and then each level presentation 
    will derive what to display out of the list of entries. 
    We always start from a full entry list and filter out some of them on every level. 
    
    We need two subsets of data: 
        1. Enumeration of all values for this level - we do not need the actual data 
        2. filtered data for the next level       
:)

declare function local:isEQto($p as xs:string, $o as item()* ){   
   let $last := count( $o )
   return if( fn:exists( $o )) then (    
       " ", $p, " = (",
         for $s at $pos in $o
         return ("'", $s, "'", if($pos < $last ) then ', ' else()),
       ") "
   )else ' false()'
};


declare function browse-data:filter-one-level(
    $level-pos as xs:int,
    $LEVELs as element(level)*,
    $URIs as element(URI)*, 
    $CATEGORIEs as element(category)*, 
    $SUBJECTs as element(subject)*  
){
   let $coll := concat($config:app-root, '/data'),
       $all-entries := ('collection("', $coll, '")/descendant-or-self::tei:div[@type="entry" ]'), (:  #all; :)
       $this-level  := $LEVELs[ $level-pos ]
       
   return if(fn:empty($URIs) and fn:empty( $CATEGORIEs ) and fn:empty($SUBJECTs) ) then (
         ()             
    )else(
      if(  $this-level = ('books', 'entries')) then (
           if( fn:empty($URIs) ) then 
               ()           
           else if( $LEVELs[ . = 'entries']/@pos > $LEVELs[ . = 'books']/@pos or
                    $LEVELs[ . = 'books']/@pos   < $LEVELs[ . = 'entries']/@pos 
              ) then  (
             (:  books, entries :)                             
               if( $this-level = "entries" and exists($URIs/node-id)) then (                                 
                  (: if node-id present then no other books are displayed :)                                   
                  if( fn:exists( $URIs[node-id] )) then "#fullPath;" else (),
                  for $u at $pos in $URIs[node-id] return ( 
                    if( $pos > 1 ) then " | " else (),
                    "util:node-by-id( doc('", $u/uri,  "'), '", $u/node-id, "' ) " 
                  )
              )else if( $this-level = "books" and exists($URIs) )   then (
                  (: whole books are loaded, follow entries fill filter by  :)
                  if( fn:exists( $URIs )) then "#fullPath;" else (),
                  for $u at $pos in $URIs return (
                     if( $pos > 1 ) then " | " else (),
                    "doc( '", $u/uri, "')//tei:body/tei:div[@type='entry'] " 
                  )                               
              )else(
                  ()
              )                             
           )else(
             (: entries, books  :)
              if( $this-level = "entries" and exists($URIs/node-id) )   then (
                 for $u at $pos in $URIs[node-id] return ( 
                    if( $pos > 1 ) then " | " else (),
                    "util:node-by-id( doc('", $u/uri,  "'), '", $u/node-id, "' ) " 
                 ) 
              )else  if( $this-level = "books" and empty( $URIs/node-id )) then (  
                 for $u at $pos in $URIs return (
                     if( $pos > 1 ) then " | " else (),
                    "doc( '", $u/uri, "')//tei:body/tei:div[@type='entry']  "
                 )
              )else(
                  ()
              )
           )
      ) else if( $this-level = 'subjects' and exists( $SUBJECTs )) then (
          "[ ", local:isEQto('@subtype', $SUBJECTs ), "]"
          
      )else if( $this-level = "names" and exists($CATEGORIEs))   then ( 
         "[./descendant-or-self::tei:name[ ",
              local:isEQto('@type', $CATEGORIEs[key='*']/name ), ' or ', 
              local:isEQto('@key',  $CATEGORIEs[ not( key = '*') ]/key ) 
              (: todo -  $CATEGORIEs[ exists(value)] :)
          ,"]] "  
      )else ()
   )
};



declare function browse-data:filter-all-levels-before(
    $prev-levels as element(level)*,
    $level-pos as xs:int,
    $LEVELs as element(level)*,
    $URIs as element(URI)*, 
    $CATEGORIEs as element(category)*, 
    $SUBJECTs as element(subject)*  
){
   let $coll := concat($config:app-root, '/data'),
       $all-entries := ('collection("', $coll, '")/descendant-or-self::tei:div[@type="entry" ]') (: #all; :)
       
   return if( $level-pos = 1 and  fn:empty($URIs) and fn:empty( $CATEGORIEs ) and fn:empty($SUBJECTs) ) then (
         $all-entries             
    )else(
      if(  not($prev-levels = ('books', 'entries')) or fn:empty($URIs) ) then (
          $all-entries
      )else (
         "( () | ",
         
           if( $LEVELs[ . = 'entries']/@pos > $LEVELs[ . = 'books']/@pos or
               $LEVELs[ . = 'books']/@pos   <  $LEVELs[ . = 'entries']/@pos 
              ) then  (
             (:  books, entries :)                             
               if( $prev-levels = "entries" and exists($URIs/node-id)) then (                                 
                  (: if node-id present then no other books are displayed :)                                   
                  for $u in $URIs[node-id] return ( "util:node-by-id( doc('", $u/uri,  "'), '", $u/node-id, "' ) | " )
              )else if( $prev-levels = "books" and exists($URIs) )   then (
                  (: whole books are loaded, follow entries fill filter by  :)
                  for $u in $URIs return ("doc( '", $u/uri, "')//tei:body/tei:div[@type='entry'] | " )                               
              )else(
                  $all-entries,
                  ' | '
              )                             
           )else(
             (: entries, books  :)
              if( $prev-levels = "entries" and exists($URIs/node-id) )   then (
                 for $u in $URIs[node-id] return ( "util:node-by-id( doc('", $u/uri,  "'), '", $u/node-id, "' ) | " ) 
              )else  if( $prev-levels = "books" and empty( $URIs/node-id )) then (  
                 for $u in $URIs return ("doc( '", $u/uri, "')//tei:body/tei:div[@type='entry'] | " )
              )else(
                  $all-entries,
                  ' | '
              )
           ),
           
         ' () )'
      ),
      
      if( $prev-levels = 'subjects' and exists( $SUBJECTs )) then (
          "[ ", local:isEQto('@subtype', $SUBJECTs ), "]"  
      )else (),                       
      if( $prev-levels = "names" and exists($CATEGORIEs))   then ( 
         "[./descendant-or-self::tei:name[ ",
              local:isEQto('@type', $CATEGORIEs[key='*']/name ), ' or ', 
              local:isEQto('@key',  $CATEGORIEs[ not( key = '*') ]/key ) 
              (: todo -  $CATEGORIEs[ exists(value)] :)
          ,"]] "  
      )else ()
   )
};

declare function browse-data:for-level( 
    $level-pos as xs:int, 
    $LEVELs as element(level)*,
    $URIs as element(URI)*, 
    $CATEGORIEs as element(category)*, 
    $SUBJECTs as element(subject)*  
 ) {    
    let $coll := concat($config:app-root, '/data'),
        $this-level  := $LEVELs[ $level-pos ],
        $prev-levels := fn:subsequence($LEVELs, 1, $level-pos ),
        $prev-prev-levels := fn:subsequence($LEVELs, 1, ($level-pos - 1) )
     
     return element query{
        attribute {'name'}{ string($this-level) },
        $this-level/@pos,
        attribute {'prev'}{ for $i in $prev-levels return string($i) },
        
        element {'data-all'}{       fn:string-join(browse-data:filter-all-levels-before($prev-prev-levels, $level-pos, $LEVELs, $URIs, $CATEGORIEs, $SUBJECTs),  '') },  
        element {'filter'}{         fn:string-join(browse-data:filter-one-level( $level-pos, $LEVELs, $URIs, $CATEGORIEs, $SUBJECTs),  '') },         
        element {'data-fitered'}{   fn:string-join(browse-data:filter-all-levels-before($prev-levels, $level-pos, $LEVELs, $URIs, $CATEGORIEs, $SUBJECTs),  '')   }
     }
};

declare function browse-data:queries-for-all-levels( 
    $LEVELs as element(level)*,
    $URIs as element(URI)*, 
    $CATEGORIEs as element(category)*, 
    $SUBJECTs as element(subject)*  
 ) {
   let $queries := for $i at $pos in $LEVELs return
        browse-data:for-level( $pos, $LEVELs, $URIs, $CATEGORIEs, $SUBJECTs )
        
   return (
       $queries,
       element query{
          attribute {'name'}{ 'grid' },
          attribute {'pos'}{ count($queries) + 1 },
          fn:subsequence($queries, count($queries), 1)/tei:data-fitered
       }
   )
};

declare function browse-data:strip-query( $q as xs:string ){ 
    if( fn:starts-with( $q, '#')) then (
       let $t := fn:tokenize($q, ';')
       return ($t[2], $t[1]) 
    )else $q    

};
