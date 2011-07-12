xquery version "1.0";

module namespace browse="http://exist-db.org/xquery/apps/matumi/browse";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace browse-entries="http://exist-db.org/xquery/apps/matumi/browse-entries" at "browse_entries.xqm";
import module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names" at "browse_names.xqm";


declare variable $browse:delimiter-uri-node := '___';
declare variable $browse:delimiter-uri-nameNode := '---';

declare variable $browse:URIs :=  (: combine multiple URI and multiple node-id :)                  
        let $u := for $i in request:get-parameter("uri", () ) return 
              element {'URI'}{ 
                  if(  contains($i,  $browse:delimiter-uri-node ) ) then (
                      element {'node-id'}{ fn:substring-after($i, $browse:delimiter-uri-node )  },
                      element {'uri'} {    fn:substring-before($i,$browse:delimiter-uri-node ) }                          
                  
                  ) else if( contains($i,  $browse:delimiter-uri-nameNode ) ) then ( 
                      attribute {'name-node'}{'true'},
                      element {'node-id'}{ fn:substring-after($i,  $browse:delimiter-uri-nameNode )  },
                      element {'uri'} {    fn:substring-before($i, $browse:delimiter-uri-nameNode ) }
                  ) else
                      element {'uri'} { $i }
              },
            $unique-uri := distinct-values( $u/uri )
          
        return (                        
            if( count($u/uri) =  count($unique-uri) ) then ( 
                  $u
               )else (
                  for $i in $unique-uri 
                  let $u2 := $u[uri = $i]
                  return element {'URI'}{
                      if( exists($u2/@name-node)) then attribute {'name-node'}{'true'} else (), 
                      element {'uri'}{ $i },
                      for $n in distinct-values($u2/node-id) 
                        return element {'node-id'}{ $n }
                  }
               )
            )
;   



declare variable $browse:levels := (
    <level value-names="name-type" title="Names" clear="name-type">names</level>, 
    <level value-names="uri" title="Entries" clear="uri_node-id">entries</level>, (:  uri=/db/matumi/data/GSE-eng.xml___3.2.2.2 :)
    <level value-names="uri" title="Books" clear="uri">books</level>             (: uri=/db/matumi/data/GSE-eng.xml :)
    (: , <level value-names="subject" title="Subjects" clear="subject">subject</level> :)
);

(:
    <level value-names="title" title="Titles" optional="yes">titles</level>
:)

declare variable $browse:L1 := ($browse:levels[ . = request:get-parameter("L1", () )], $browse:levels[1])[1];
declare variable $browse:L2 := ($browse:levels[ . = request:get-parameter("L2", () )], $browse:levels[ not(. = $browse:L1) ])[1];
declare variable $browse:L3 := ($browse:levels[ . = request:get-parameter("L3", () )], $browse:levels[ not(. = ($browse:L1,$browse:L2)) ])[1];
declare variable $browse:L4 := ($browse:levels[ . = request:get-parameter("L4", () )], $browse:levels[ not(. = ($browse:L1,$browse:L2,$browse:L3)) ])[1];

declare variable $browse:data-1 := 
          if(      $browse:L1 = 'books')   then  browse-books:data( (), $browse:URIs, 1)            
          else if( $browse:L1 = 'entries') then  browse-entries:data( (),  $browse:URIs, 1)  
          else if( $browse:L1 = 'names')   then  browse-names:data( (), $browse:URIs, 1)      
          else();

declare variable $browse:data-2 := 
            if(      $browse:L2 = 'names')   then browse-names:data(   $browse:data-1, $browse:URIs, 2)
            else if( $browse:L2 = 'entries') then browse-entries:data( $browse:data-1, $browse:URIs, 2)
            else if( $browse:L2 = 'books')   then browse-books:data(   $browse:data-1, $browse:URIs, 2)                 
            else ();

declare variable $browse:data-3 := 
            if(      $browse:L3 = 'names')   then browse-names:data(   $browse:data-2, $browse:URIs, 3)
            else if( $browse:L3 = 'entries') then browse-entries:data( $browse:data-2, $browse:URIs, 3)
            else if( $browse:L3 = 'books')   then browse-books:data(   $browse:data-2, $browse:URIs, 3)                 
            else ();

declare variable $browse:data-4 := ();

declare variable $browse:titles-1 := if( empty($browse:data-1) or empty($browse:L1)) then () else 
       typeswitch ($browse:data-1[1] )
          case element(tei:TEI) return   browse-books:titles-list( $browse:data-1, $browse:L1 )                
          case element(tei:div) return   browse-entries:titles-list( $browse:data-1, $browse:L1 )
          case element(tei:name) return browse-names:titles-list( $browse:data-1, $browse:L1 )          
          default return <titles><title>no-titles</title></titles>;
                   
declare variable $browse:titles-2 := if( empty($browse:data-2) or empty($browse:L2)) then () else 
        typeswitch ($browse:data-2[1] ) 
          case element(tei:TEI) return   browse-books:titles-list( $browse:data-2, $browse:L2 )                
          case element(tei:div) return   browse-entries:titles-list( $browse:data-2, $browse:L2 )
          case element(tei:name) return browse-names:titles-list( $browse:data-2, $browse:L2 ) 
          default return <titles><title>no-titles</title>{ $browse:data-2[1] }</titles>;
    
declare variable $browse:titles-3 := if( empty($browse:data-3) or empty($browse:L3) ) then () else 
        typeswitch ($browse:data-3[1] ) 
          case element(tei:TEI) return   browse-books:titles-list( $browse:data-3, $browse:L3 )                
          case element(tei:div) return   browse-entries:titles-list( $browse:data-3, $browse:L3 )
          case element(tei:name) return browse-names:titles-list( $browse:data-3, $browse:L3 ) 
          default return <titles><title>no-titles</title>{ $browse:data-2[1] }</titles>;

declare variable $browse:titles-4 := if( empty($browse:data-4) or empty($browse:L4) ) then () else 
        typeswitch ($browse:data-4[1] ) 
          case element(tei:TEI) return   browse-books:titles-list( $browse:data-3, $browse:L3 )                
          case element(tei:div) return   browse-entries:titles-list( $browse:data-3, $browse:L3 )
          case element(tei:name) return browse-names:titles-list( $browse:data-3, $browse:L3 ) 
          default return <titles><title>no-titles</title>{ $browse:data-2[1] }</titles>;

declare variable $browse:entries := 
      if( $browse:L1 = 'entries' ) then $browse:data-1
      else if( $browse:L2 = 'entries' ) then $browse:data-2
      else if( $browse:L3 = 'entries' ) then $browse:data-3
      else if( $browse:L4 = 'entries' ) then $browse:data-4
      else ();


declare function browse:levels-combo( $level as node(), $pos as xs:int ) as element(select) {
   <select name="L{$pos}" id="L{$pos}" style="width:100%">{
       for $L in $browse:levels return 
       element {'option'}{
           if( $L is $level ) then (
                attribute {'selected'}{'selected'} 
           )else if( $pos = 2 and $L is $browse:L1) then (
                attribute {'disabled'}{'disabled'},
                attribute {'style'}{'display:none'}
           )else (),
           if($pos = 3 ) then (
              if( $L is $browse:L1 or $L is $browse:L2 ) then( 
                   attribute {'disabled'}{'disabled'},
                   attribute {'style'}{'display:none'}
              )else ()
           )else(),     
           attribute {'value'}{ string($L)},
           string($L/@title)
       }
   }</select>
};

(:~
 : create file-node URI depending on the type of the element node.
 :)
declare function browse:makeDocument-Node-URI( $node as node() ) as xs:string {
  fn:string-join((
       document-uri( root($node)),       
       typeswitch ( $node )
          case element(tei:div)  return $browse:delimiter-uri-node
          case element(tei:name) return $browse:delimiter-uri-nameNode
          default return '_node-id_',
       util:node-id($node)
  ),'')

};

(:  local:change-element-ns-deep($x, "http://www.w3.org/1999/xhtml")  :)
declare function browse:change-element-ns-deep ($element as element(), $newns as xs:string) as element(){
  let $newName := QName($newns, local-name($element))
  return
  (element {$newName} {
    $element/@*, for $child in $element/node()
      return
        if ($child instance of element())
        then browse:change-element-ns-deep($child, $newns)
        else $child
  })
};


declare function browse:nameValue( $nodes as item()* ) as xs:string*{
   for $n in $nodes return
   concat( local-name($n), '=', string($n))
};

declare function browse:nameValue( $name as xs:string, $values as xs:string* ) as xs:string?{
   if( exists($values) ) then    
       string-join((
         for $v in $values return
         concat( $name, '=', $v )
        ), '&amp;') 
   else ()
};

declare function browse:link-href-base( $add-uri as xs:boolean ) as xs:string?{
    string-join((
       browse:nameValue('L1', $browse:L1),
       browse:nameValue('L2', $browse:L2),
       browse:nameValue('L3', $browse:L3),
       browse:nameValue('name-type', request:get-parameter("name-type", () )),
       if( $add-uri ) then 
          browse:nameValue('uri',  for $uri in distinct-values(request:get-parameter("uri", () )) return $uri )
       else ()
    ),'&amp;')
};

declare function browse:link-href-param( $param-names as xs:string* )as xs:string?{
    string-join((
       for $p in $param-names return
          browse:nameValue($p,  request:get-parameter($p, ()  ) )
    ),'&amp;')
};

declare function browse:link( $title as element() ) as element(a){
  element a {
     if( exists($title/@title)) then 
        $title/@title 
     else attribute {'title'}{},
     if( exists($title/@href)) then 
        $title/@href
     else   
        attribute{'href'}{
           concat('?',
               string-join((
                  browse:link-href-base( true()),
                  browse:nameValue( $title/@* )               
               ),'&amp;')
           )     
        },
     
     string( $title )  
  }
};


declare function browse:clean-link( $level as element(), $step as xs:int ) as xs:string {
    let $param := for $p in request:get-parameter-names() return element {$p} { request:get-parameter($i, () ) }
    let $exclude := $level
    
    return
    concat('?',
           string-join((
              browse:link-href-base( true()),
              browse:nameValue( $title/@* )               
           ),'&amp;')
       )     
};

declare function browse:section-as-ul( $section as element(titles)?, $id as node()?, $pos as xs:int) {
    <div class="grid_5">
		<div class="box L-box">
			<h2>{browse:levels-combo( $id,  $pos) }</h2>
			<div class="block L-block">
                <ul id="{ $id }">{ 
                    <li style="margin-left:0;list-style:none">
                       <a href="?{              
                             string-join((
                               browse:nameValue('L1', $browse:L1),
                               browse:nameValue('L2', $browse:L2),
                               browse:nameValue('L3', $browse:L3),
                               browse:nameValue('L4', $browse:L4)
                            ),'&amp;')
                          }">All ({ count($section/title), ' ',  string($section/@title)} )</a>        
                      
                    </li>,
                    for $t in $section/title return 
                    element li { browse:link($t) }
               }</ul>                
            </div>
		</div>
	</div>
};

declare function browse:level-boxes(){
   <form id="browseForm" action="?">{ 
    browse:section-as-ul( $browse:titles-1, $browse:L1, 1 ),
	browse:section-as-ul( $browse:titles-2, $browse:L2, 2 ),
	browse:section-as-ul( $browse:titles-3, $browse:L3, 3 ),
	<div class="clear"></div>
   }</form>,
   <script>
        function browse_Set_L3( event, $L1, $L2, $L3){{
            var $autoUpdate = $('#autoUpdate');
            $L1 = $L1 || $('#L1');
            $L2 = $L2 || $('#L2');    
            $L3 = $L3 || $('#L3');    
            $('option:disabled', $L3).removeAttr('disabled').show();
            $('option[value=' + $L1.val() + '], option[value=' + $L2.val() + '] ', $L3).attr('disabled', 'true' ).hide();
            $L3.val( $L3.find('option:enabled').eq(0).attr('value')); 
            
            if( $autoUpdate.length == 0 || $autoUpdate.is(':checked')) {{   
               $('#browseForm').submit();
            }}             
        }}        
        $(document).ready(function() {{
            $('#L1').live('change', function(event){{
                 var $L1 = $(event.target),
                     $L2 = $('#L2'),
                     $L3 = $('#L3'),
                     v1 = $L1.val(),
                     v2 = $L2.val(),
                     v3 = $L3.val();
                 
                 $('#browseForm option:disabled').removeAttr('disabled').show();
                 $('#L2 option[value=' + v1 + ']').attr('disabled', 'true' ).hide();
                 if( v2 == v1 ) {{ 
                     $L2.val( $L2.find('option:enabled').eq(0).attr('value')); 
                 }}
                 browse_Set_L3(null, $L1, $L2, $L3 );
            }});
            
            $('#L2').live('change', browse_Set_L3 );
        }});
   </script>
};




declare function browse:page-grid( $show-all as xs:boolean ){ 
 	if( $show-all or exists($browse:URIs) or string-length(request:get-parameter("name-type", () )) > 0 ) then ( 	
     	<table summary="Table summary">		
    		<colgroup>
    			<col class="colA" />
    			<col class="colB" />
    			<col class="colC" />
    			<col class="colD" />
    		</colgroup>
    		<thead>
    			<tr>
    				<th colspan="4" class="table-head">Table heading</th>
    			</tr>
    			<tr>
    				<th width="15%" >Book</th>
    				<th width="10%" >Subject</th>
    				<th width="25%" >Entry</th>
    				<th width="50%" >Categories</th>
    			</tr>
    		</thead>
    		<tbody>{
    			 for $e at $pos in $browse:entries
                  let $root := $e/ancestor-or-self::tei:TEI,
    			      $uri  := document-uri( root($e)),
    			      $document-title := browse-books:title-extract($root//teiHeader/fileDesc/titleStmt),
    			      $node-id := util:node-id($e),
    			      $categories := browse-names:extract-categories($e)
    			 
    			 return <tr class="{ if( $pos mod 2 = 0 ) then 'odd' else ()}">{
    				element {'td'}{ string($document-title)},
    				<td>{ string($e/@subtype )}</td>,
    				<td>{ browse-entries:direct-link($e)}</td>,
    				<td>{  
    				    for $c in $categories 
    				    let $total := sum($c/name/@count)
    				    return
    				    <div>
    				       <span class="cat-name">{ 
    				            attribute {'title'}{ concat(  $c/@count, ' unique keys and ', $total, ' instaces'   )},
    				            string($c/@name),
    				            concat('(', $c/@count,'/', $total ,')')				            
    				       }:</span>
    				       {
    				         for $n at $pos in $c/name 
    				         let $title := concat( $n/@count,' instances in this document')
    				         return(
    				         <a title="{$title}" class="cat-value-deep-link" 
    				            href="{ concat('entry.html?doc=', $uri, 
    				                            '&amp;node=',$node-id, 
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
    				}</td>
    			}</tr>
    	    }</tbody>
    	</table>
    )else(
       (: may be we can display a shot text to explain there will be a grid only when something is selected from the lists? :)
    )
};

