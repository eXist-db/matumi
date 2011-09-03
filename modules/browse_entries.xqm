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
import module namespace browse-data="http://exist-db.org/xquery/apps/matumi/browse-data" at "browse_data.xqm";

(: I have an error "Can not find the ICU4J library in the classpath com.ibm.icu.text.Normalizer " when using fn:normalize-unicode :)
declare function browse-entries:heads-with-same-xmlID( $xml-id as xs:string* ) as node()*  { 
     for $i in browse-books:data-all((), (), true())//head[ .//@xml:id = $xml-id ] 
     let $s := fn:normalize-space(string($i))
     order by string($i/@xml:id), $s
     return element {'head'}{
         attribute {'xml-id'}{ string( $i//@xml:id[1] ) },
         attribute {'node-id'}{ util:node-id($i) },
         attribute {'uri' }{ document-uri( root($i)) },
         $s 
     }     
};

declare function browse-entries:alternative-titles( $entry as element()? ) as xs:string* { 
   let $xml-id := string($entry/head//@xml:id)
   let $main-title := string( $entry/tei:head[not(@type='alt')][1] )
   let $same-xmlID := browse-entries:heads-with-same-xmlID( $xml-id )
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

declare function browse-entries:titles-list-fast( $QUERIEs as element(query)*,  $level as node()?, $URIs as node()*, $Categories as element(category)* ){
    let $nodes := browse-data:execute-query( $QUERIEs[@name= $level ] ) 
    
    return  element titles {
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
