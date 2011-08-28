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


declare function metadata:all($node as node()*, $params as element(parameters)?, $model as item()*) {
   let $books := browse-books:data-all( (), (), true()),
       $uri := ( request:get-parameter("uri", () ), document-uri( $books[1] ))[1],
       $uri-annotation := concat( fn:substring-before($uri, '.xml'), '-annotations.xml'),
       $doc := doc($uri)/*, 
       $doc-annotation := if( fn:doc-available( $uri-annotation ) ) then doc($uri-annotation)/* else (),
       $annotation-body := $doc-annotation/tei:body,
       
       $fileDesc   := $doc/tei:teiHeader//tei:fileDesc,
       $sourceDesc :=  $fileDesc/tei:sourceDesc,
       $biblFull   :=  $sourceDesc/tei:biblFull,
       $msDesc     :=  $sourceDesc/tei:msDesc,      
       $profileDesc := $doc/tei:teiHeader//tei:profileDesc

   return
    <div class="grid_16 entry-view">
      <form id="metadataForm" action="{if( fn:contains(request:get-url(), '?')) then fn:substring-before(request:get-url(), '?') else request:get-url() }">{
    
       browse:section-parameters-combo( 
             browse-books:titles-list( $books, (), $browse:URIs,() ),
             <level value-names="uri" title="Books" ajax-if-more-then="-1" class="">matadataBooks</level>,
             false(),
             false()
         ) 
     }</form>
    
      <div> 
          <h2>Source Description</h2>      
           <table class="metadata" cellspacing="3" cellpadding="3"  width="100%">
             <tbody>{
                metadata:process('Title',         $biblFull/tei:titleStmt/tei:title ),
                metadata:process('Author',        $biblFull/tei:titleStmt/tei:author ),
                metadata:process('Editor',        $biblFull/tei:titleStmt/tei:editor ),
                metadata:process('Publisher',     $biblFull/tei:publicationStmt/tei:publisher ),
                metadata:process('Date',          $biblFull/tei:editionStmt/tei:date),
                metadata:process('Edition',       $biblFull/tei:editionStmt/tei:edition ),
                metadata:process('Other editions',$biblFull/tei:notesStmt ),
                metadata:process('Physical Description',  $msDesc/tei:physDesc),
                metadata:process('Content',       $msDesc/tei:msPart/tei:msContents ),
                metadata:process('History of the manuscript',       $msDesc/tei:msPart/tei:history )
    
             }</tbody>
           </table>
           
         <h2>Profile Description</h2>      
           <table class="metadata" cellspacing="3" cellpadding="3"  width="100%">
             <tbody>{
                 metadata:process('Language',                          $profileDesc/tei:langUsage ),
                 metadata:process('Publication circumstances',         $profileDesc/tei:settingDesc ),
                 metadata:process('Background of authors and editors', $profileDesc/tei:particDesc/tei:listPerson ),
                 metadata:process('Genre and style',                   $profileDesc/tei:textDesc ) 
             }</tbody>
           </table>

         <h2>Analysis</h2>      
           <table class="metadata" cellspacing="3" cellpadding="3"  width="100%">
             <tbody>{
                 metadata:process('Translations of Prefaces',       $annotation-body/tei:div/@type[. = 'preface-translation']),
                 metadata:process('Analysis of Prefaces',           $annotation-body/tei:div/@type[. = 'preface-analysis']),
                 metadata:process('Analysis of advertisements for this book',      $annotation-body/tei:div/@type[. = 'advertisement-analysis']),
                 metadata:process('Advertisements in this books',   $annotation-body/tei:div/@type[. = 'advertisement-for-this-book']),
                 metadata:process('Analysis of readership',                     $annotation-body/tei:div/@type[. = 'readership']),
                 metadata:process('Hidden grammars - underlying world view or intention', $annotation-body/tei:div/@type[. = 'HiddenGrammars']),
                 metadata:process('Secondary literature  on this encyclopedia',           $annotation-body/tei:div/@type[. = 'secondary-literature']),
                 metadata:process('Open Questions',                 $annotation-body/tei:div/@type[. = 'open-questions']),
              (:   metadata:process('', $annotation-body/tei:div/@type[. = '']),    add more if necessary  :)
                 ()
             }</tbody>
           </table>
     </div>     
  </div>  
  
};

