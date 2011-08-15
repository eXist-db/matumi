xquery version "1.0";

module namespace browse-entries="http://exist-db.org/xquery/apps/matumi/browse-entries";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm"; 
(: import module namespace browse-config="http://exist-db.org/xquery/apps/matumi/browse-config" at "browse_config.xqm"; :)
import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";

declare function browse-entries:data-all( $context-nodes as node()*, $level as node(),  $root as xs:boolean ){
   if( $root ) then 
        collection(concat($config:app-root, '/data'))//tei:body/tei:div[@type="entry"]    
   else typeswitch ($context-nodes[1] )
          case element(tei:TEI)  return $context-nodes//tei:body/tei:div[@type="entry"]
          case element(tei:name) return $context-nodes/ancestor-or-self::tei:div[@type="entry"]    
         default                 return <error type="unknown-context-data-element"/>       
};

declare function browse-entries:data-filtered( $data as node()*, $level as node(),  $URIs as node()*, $Categories as element(category)* ){
    if( empty($URIs) )then (
             $data   
    )else (
       let $urls := if( exists($URIs/node-id)) then $URIs[node-id] else $URIs
       return for $d in $data 
           let $this-param-URI := $urls[ uri = document-uri( root($d) )  ]
           return    
            if( exists($this-param-URI) ) then(
                if( empty( $this-param-URI/node-id  ) or $this-param-URI/node-id   = util:node-id($d)  ) then (
                      $d
                )else ()        
            )else ()          
    )  
};

declare function browse-entries:filtered( $data as node()*, $URIs as element(URI)*, $Categories as element(category)* ){       
    let $step1 := 
        if(  exists($URIs/node-id) ) then (
            $URIs/node-id,           
            $data[ util:node-id(.) = $URIs/node-id and document-uri( root(.)) = $URIs/uri  ]
        )else (  
            <no-node-id/>,
            $URIs,
            $URIs/tei:node-id,
            $data
        )            
  
    return  if(  exists($Categories/name) ) then (
            let $names-with-values := if( exists( $Categories/value) ) then 
                           for $n in $data/descendant-or-self::tei:name[  empty(@key) and @type =  $Categories/name ]
                           return if( exists( $Categories[ name = $n/@type and value = fn:normalize-space($n )  ])) then 
                                     $n
                                  else ()
                        else ()
                
               
            return  (if( exists($Categories[key='*']) ) then (
                       $data[  ./descendant-or-self::tei:name[ @type = $Categories[key='*']/name ] ]
                    )else ())
                    |
                    (if( exists($Categories[ key != '*']) ) then
                       $data[  ./descendant-or-self::tei:name[ @key = $Categories/key[not(. = '*') ] ]]
                    else ())                       
                    | 
                   $names-with-values/ancestor-or-self::tei:div[@type="entry"]   
       ) else 
              $step1
};



(:
     let $c-selected := $Categories[ name = $c/@name and key = '*' ]
            for $t in $c/*  
            let $c-selected := if( exists( $t/@value-insted-of-key )) then            
                                    $Categories[  name = $c/@name and value = $t/@key  ]
                               else $Categories[  name = $c/@name and key = $t/@key ]
:)

declare function browse-entries:alternative-titles( $entry as element()? ) as xs:string* { 
   let $xml-id := string($entry/head//@xml:id)
   let $main-title := string( $entry/tei:head[not(@type='alt')][1] )
   let $same-xmlID := browse:heads-with-same-xmlID( $xml-id )
   for $i in fn:distinct-values( ($same-xmlID[@xml-id =$xml-id ][ not(. = $main-title )], $entry/tei:head[ .//@type='alt'])  ) 
   order by $i
   return $i 
};
declare function browse-entries:title-extract( $entry as element()? ){ 
   element title {
     attribute {'doc'}{ document-uri( root($entry)) },
     attribute {'node'}{ util:node-id($entry)},
     $entry/tei:head[not(@type='alt')][1]
   }     
};


declare function browse-entries:direct-link( $entry as element()? ){ 
   let $title := browse-entries:title-extract( $entry )
   return element a {
     attribute {'class'}{ 'entry-derect-link' },
     attribute {'href'}{ concat('entry.html?doc=', $title/@doc, '&amp;node=',$title/@node)},
     string($title)
   }     
};

declare function browse-entries:titles-list( $nodes as node()*,  $level as element(level)?, $URIs as element(URI)*, $Categories as element(category)*  ){
    
    element titles {
        attribute {'name'}{ 'entry-uri' },
        attribute {'count'}{ count($nodes)},
        attribute {'title'}{ $level/@title },
        element {'group'}{
            for $n in $nodes 
             let $title := $n/tei:head[not(@type='alt')][1] 
             order by string($title)
             return 
                element {'title'} {
                     if( $URIs[uri =  document-uri( root($n)) and node-id = util:node-id($n) ]  ) then attribute {'selected'}{'true'} else (),
                     attribute {'value'} {  browse:makeDocument-Node-URI( $n ) },  
                     attribute{'xml-id'}{ string($n/head//@xml:id[1]) },
                     attribute{'node-id'}{ util:node-id($n) },                     
                     $title,
                     $n/tei:head[ @type='alt']
                }
       }
    }    
};

