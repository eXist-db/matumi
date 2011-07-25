xquery version "1.0";

module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function browse-books:data-all( $context-nodes as node()*, $root as xs:boolean ){
   if( $root ) then 
        collection(concat($config:app-root, '/data'))//tei:TEI        
   else $context-nodes/ancestor-or-self::tei:TEI
};

declare function browse-books:data-filtered( $data as node()*, $URIs as node()*, $Categories as element(category)* ){       
    if(  exists($URIs) ) then (
        for $d in $data return
        if( document-uri( root($d)) =  $URIs/uri ) then 
            $d 
        else ()
    )else   
        $data    
};

declare function browse-books:title-extract( $title as element(tei:titleStmt)?, $URIs as node()* ){     
     if( exists($title)) then
         let $root := root($title)
         let $uri := document-uri( $root ) 
         return element title {
            if( $uri = $URIs/uri ) then attribute {'selected'}{'true'} else (),
            attribute {'language'}{ string($root/text/@xml:lang)  },     
            attribute {'value'} { $uri },            
            attribute {'uri'} { $uri },
            
            if( exists($title/title[@type='main']) ) then
                 $title/title[@type="main"]   
            else if( string($title) = 'Title' or empty($title/title) or fn:string-join($title/title,'') = '' ) then 
                 concat('[',  util:document-name($title), ']') 
            else $title/title
         }   
     else <title>Missing Title</title>
};


declare function browse-books:titles-list( $nodes as element()*,  $level as node()?, $URIs as node()*, $Categories as element(category)* ){
    element titles {
         attribute {'name'}{ 'uri' },
         attribute {'count'}{ count($nodes)},
         attribute {'title'}{ $level/@title },
         element {'group'}{
             for $title in $nodes//tei:fileDesc/tei:titleStmt
             let $title2 := browse-books:title-extract($title, $URIs )
             order by string($title2)
             return $title2
         }
    }    
};
