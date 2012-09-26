module namespace metadata="http://exist-db.org/xquery/apps/matumi/metadata";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace xf="http://www.w3.org/TR/2002/WD-xquery-operators-20020816";

import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace links-to="http://exist-db.org/xquery/apps/matumi/links-to" at "links-to.xqm";

declare function local:capitalize-first($str as xs:string) as xs:string {
    concat(upper-case(substring($str,1,1)), substring($str,2))
 };

declare function local:get-textdescname($str as xs:string) as xs:string {
    if      ($str eq "Channel")         then <span>Medium</span> 
    else if ($str eq "Constitution")    then <span>Constitution</span>
    else if ($str eq "Derivation")      then <span>Derivation</span>
    else if ($str eq "Domain")          then <span>Domain</span>
    else if ($str eq "Factuality")      then <span>Factuality</span>
    else if ($str eq "Interaction")     then <span>Interaction</span>
    else if ($str eq "Preparedness")    then <span>Preparedness</span>
    else if ($str eq "Purpose")         then <span>Purpose</span>
    else <span>[Item]</span>
 };
 
 declare function local:get-textdescinfo($str as xs:string) as xs:string {
    if      ($str eq "Channel")         then <span>? 'Channel' describes the medium or channel by which a text is delivered or experienced. For a written text, this might be print, manuscript, e-mail, etc.; for a spoken one, radio, telephone, face-to-face, etc.</span>
    else if ($str eq "Constitution")    then <span>? 'Constitution' describes the internal composition of a text or text sample, for example as fragmentary, complete, etc.</span>
    else if ($str eq "Derivation")      then <span>? 'Derivation' describes the nature and extent of originality of this text.</span>
    else if ($str eq "Domain")          then <span>? 'Domain' (domain of use) describes the most important social context in which the text was realized or for which it is intended, for example private vs. public, education, religion, etc.</span>
    else if ($str eq "Factuality")      then <span>? 'Factuality' describes the extent to which the text may be regarded as imaginative or non-imaginative, that is, as describing a fictional or a non-fictional world. </span>
    else if ($str eq "Interaction")     then <span>? 'Interaction' describes the extent, cardinality and nature of any interaction among those producing and experiencing the text, for example in the form of response or interjection, commentary, etc.</span>
    else if ($str eq "Preparedness")    then <span>? 'Preparedness' describes the extent to which a text may be regarded as prepared or spontaneous. </span>
    else if ($str eq "Purpose")         then <span>? 'Puropse' characterizes a single purpose or communicative function of the text.</span>
    else <span>[Item]</span>
 };
declare function local:get-textdescdesc($str as xs:string) as xs:string {
    if      ($str eq "Channel")         then <span>print / manuscript / scan / other</span>
    else if ($str eq "Constitution")    then <span>one single complete text / composition of single complete texts / fragments / other</span>
    else if ($str eq "Derivation")      then <span>original / revision / translation / abridgment / plagiarism / traditional / other</span>
    else if ($str eq "Domain")          then <span>education / government / public / domestic / religion / business / art / other</span>
    else if ($str eq "Factuality")      then <span>fiction / fact / mixed</span>
    else if ($str eq "Interaction")     then <span>interaction among those producing and experiencing the text</span>
    else if ($str eq "Preparedness")    then <span>spontaneous / formulaic / revised</span>
    else if ($str eq "Purpose")         then <span>inform / entertain / persuade / express</span>
    else <span>[Item]</span>
 };
 
declare function metadata:process-child-nodes($Node as node()?) {
    for $N in $Node/node() return metadata:process( (), $N ) 
};

declare function metadata:genre-and-style-element( $e as node() ){
    let $other-attr := $e/@*[local-name()!= 'type'],
        $name := local:capitalize-first(local-name($e)),
        $textdescname := local:get-textdescname($name),
        $textdescinfo := local:get-textdescinfo($name),
        $textdescdesc := local:get-textdescdesc($name)
      
     return <div class="textDesc { string($e/@type) }">
              <span class="typeName">{ $textdescname }</span>
              <span class="textinfo">{ $textdescinfo }</span>
              <span class="textdescription"> ({ $textdescdesc })</span>:<br/> {
                if( fn:exists( $e/@type )) then (
                  ':', 
                  <span class="typeValue">{string($e/@type)}</span>
                )else(),
                if( fn:exists( $e/@mode )) then (                  
                  <span class="typeValue">written</span>
                )else(),
             (:   for $a in $other-attr return ( 
                    ', ',
                    <span class="typeNameOther">{  local-name($a) } </span>, 
                    ':', <span class="typeValueOther">{ string($a) }</span>
                ),
             :)   
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