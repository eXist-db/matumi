xquery version "1.0";

module namespace browse-entries="http://exist-db.org/xquery/apps/matumi/browse-entries";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";

declare function browse-entries:data( $context-nodes as node()*, $URIs as node()*, $level-pos as xs:int ){ 
   if( $level-pos = 1 ) then (
        (:   no context nodes expected   :) 
        if( exists($URIs) ) then (           
               for $U in  $URIs
               let $node-ids := $U/node-id
               return 
                   if( doc-available($U/uri)) then (
                      if( empty( $node-ids )) then (                
                          doc($U/uri)//tei:body/tei:div[@type="entry"]
                      )else (
                          for $n in $node-ids return (
                             util:node-by-id( doc($U/uri), $n)/descendant-or-self::tei:body/tei:div[@type="entry"]
                          )
                      )    
                   )else <error type="bad-uri">{ $U }</error>           
               
        )else ( 
           (:   all available data   :)
           collection(concat($config:app-root, '/data'))//tei:body/tei:div[@type="entry"]
        )
    )else (
       let $data := () | (
        typeswitch ($context-nodes[1] )
          case element(tei:TEI)  return $context-nodes//tei:body/tei:div[@type="entry"]
          case element(tei:name) return $context-nodes/ancestor-or-self::tei:div[@type="entry"]    
         default                 return <error type="unknown-context-data-element"/>
       )
       return if( exists($URIs) ) then (
           for $d in $data 
           let $this-node-uri := document-uri( root($d))           
           let $this-param-URI := $URIs[ uri = $this-node-uri ]
           return    
            if( exists($this-param-URI) ) then(
               let $node-ids := $this-param-URI/node-id
               let $this-node-id := util:node-id($d)
               return if( empty( $node-ids ) or $this-node-id  =  $node-ids ) then (
                            $d
                      )else ()        
            )else ()                    
       )else $data
    )
};

declare function browse-entries:title-extract( $entry as element()? ){ 
   element title {
     attribute {'doc'}{ document-uri( root($entry)) },
     attribute {'node'}{ util:node-id($entry)},
     $entry/tei:head[1]
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


declare function browse-entries:titles-list( $nodes as element()*,  $level as node()? ){
    element titles {
        attribute {'name'}{ 'entity-uri' },
        attribute {'count'}{ count($nodes)},
        attribute {'title'}{ $level/@title },
        
        for $n in $nodes 
         let $title := $n/tei:head[1] 
         order by string($title)
         return 
            element title { 
                 attribute uri { browse:makeDocument-Node-URI( $n ) },
                 $title 
            }
    }    
};

