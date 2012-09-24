module namespace metadata="http://exist-db.org/xquery/apps/matumi/metadata";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xf="http://www.w3.org/TR/2002/WD-xquery-operators-20020816";

import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace links-to="http://exist-db.org/xquery/apps/matumi/links-to" at "links-to.xqm";

declare function local:capitalize-first($str as xs:string) as xs:string {
    concat(upper-case(substring($str,1,1)), substring($str,2))
 };


declare function metadata:process-child-nodes($Node as node()?) {
    for $N in $Node/node() return metadata:process( (), $N ) 
};

declare function metadata:genre-and-style-element( $e as node() ){
    let $other-attr := $e/@*[local-name()!= 'type'],
        $name := local:capitalize-first(local-name($e))
      
    return <div class="textDesc { string($e/@type) }">
              <span class="typeName">{ $name }</span>{
                if( fn:exists( $e/@type )) then (
                  ':', 
                  <span class="typeValue">{string($e/@type)}</span>
                )else(),
                for $a in $other-attr return ( 
                    ', ',
                    <span class="typeNameOther">{  local-name($a) } </span>, 
                    ':', <span class="typeValueOther">{ string($a) }</span>
                ),
                if( $e/node() ) then (' - ', metadata:process-child-nodes($e) ) else() 
          }</div>
};

declare function metadata:book-articles-list( $doc as node() ){
     <tr>
        <th >Articles in this encyclopedia</th>
        <td> <ul id="entries-links">{
            for $e in $doc/tei:text/tei:body/tei:div[@type="entry"]                    
            let $title := fn:string-join($e/tei:head, ', ') 
            return element {'li'}{
               element a {
                  attribute {'class'}{ 'entry-derect-link' },
                  attribute {'href'}{ concat('entry.html?doc=', document-uri( root($e)), '&amp;node=',util:node-id($e))},    
                  $title
                }     
            }
        }</ul>
        </td>
      </tr>           
};         

declare function metadata:process-child-nodes($Node as node()?, $separator as xs:string?) {
    let $L := count($Node/*)
    for $N in $Node/node() return (
        metadata:process( (), $N )
    )        
};


declare function metadata:person-link( $person as element(person)) as element (a) {
      <a class="{$node/@role} role person" href="{ ($node/@key | $node/@ref )[1]}" target="_new">{
         if( fn:exists($node/xml:id) ) then attribute {'title'}{ $node/xml:id }else(),
         if( fn:exists($node/@xml:id) ) then attribute {'title'}{ $node/@xml:id }else(),
         metadata:process-child-nodes($node/persName)  
     }</a>
};


declare function metadata:process($label as xs:string?, $Nodes as node()* ) {
    let $n := for $node in $Nodes return
            typeswitch($node)
                 case text()                 return ( normalize-space($node) )
                 case element(tei:channel)   return()
                 case element(tei:lb)        return  <br/>     
(:               case element(tei:title)     return  metadata:process-child-nodes($node)
                 case element(tei:physDesc)  return  metadata:process-child-nodes($node)
:)                 
                 case element(tei:p)         return  <p>{ metadata:process-child-nodes($node) }</p>                     
                 case element(tei:author)    return <div>{  metadata:process-child-nodes($node) }</div>
                 case element(tei:editor)    return <div>{  metadata:process-child-nodes($node) }</div>
                 
                 case element(tei:notesStmt) return <ul class="editions">{  metadata:process-child-nodes($node) }</ul>                         
                 case element(tei:note)      return <li>{   metadata:process-child-nodes($node) }</li>
            
                 case element(tei:name) return ( ' ', 
                         <a class="{$node/@type} name" href="{ ($node/@key | $node/@ref )[1]}" target="_new">{  
                             if( fn:exists($node/@xml:id) ) then attribute {'title'}{ $node/@xml:id }else(),
                             if( fn:exists($node/@exist:id) ) then attribute {'id'}{  $node/@exist:id }else(),
                             metadata:process-child-nodes($node)  
                         }</a>,' ')
    
                case element(tei:person) return 
                      <div class="person-listed">
                         <div>{ links-to:person($node, $node/tei:persName ), ', ', string($node/@role) }</div>
                         <div>{ metadata:process-child-nodes($node/note) }</div>
                     </div>
                
                case element(tei:textDesc) return for $i in $node/* return metadata:genre-and-style-element( $i )
 
                case attribute(type) return  $node/parent::tei:div 

                (: container nodes will be processed further :)
                default return metadata:process-child-nodes($node) 

      return if( fn:exists($label)) then 
         <tr>
            <th width="250px" nowrap="nowrap">{ $label }</th>
            <td>{ $n  }</td> 
         </tr>       
      else $n
};