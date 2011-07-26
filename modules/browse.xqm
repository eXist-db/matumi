xquery version "1.0";

module namespace browse="http://exist-db.org/xquery/apps/matumi/browse";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace cache="http://exist-db.org/xquery/cache" at "java:org.exist.xquery.modules.cache.CacheModule";
import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace browse-entries="http://exist-db.org/xquery/apps/matumi/browse-entries" at "browse_entries.xqm";
import module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names" at "browse_names.xqm";


declare variable $browse:ajax-load := false();
declare variable $browse:use-combo-plugin := true(); (: chzn-select :)
declare variable $browse:drop-combo-plugin-limit := 125; (: switch to a clasic dropdown for better performance. To be fixed :)
declare variable $browse:categories-table-ajax-limit := 100;


declare variable $browse:use-cached-data := request:get-parameter("use-cached-data", 'yes' );

declare variable $browse:controller-url := request:get-parameter("controller-url", 'missing-controller-url');
declare variable $browse:delimiter-uri-node := '___';
declare variable $browse:delimiter-uri-nameNode := '---';

declare variable $browse:cache := cache:cache('matumi-browse');

declare variable $browse:levels := (
    <level value-names="uri" title="Books" ajax-if-more-then="-1" class="chzn-select">books</level>,             (: uri=/db/matumi/data/GSE-eng.xml :)
    <level value-names="entry-uri" title="Entries" ajax-if-more-then="50" class="chzn-select" >entries</level>, (:  uri=/db/matumi/data/GSE-eng.xml___3.2.2.2 :)
    <level value-names="category" title="Names" ajax-if-more-then="50">names</level>
    (: , <level value-names="subject" title="Subjects">subject</level> :)
);

declare variable $browse:LEVELS := 
    let $L1 := ($browse:levels[ . = request:get-parameter("L1", () )], $browse:levels[1])[1],
        $L2 := ($browse:levels[ . = request:get-parameter("L2", () )], $browse:levels[ not(. = $L1) ])[1],
        $L3 := ($browse:levels[ . = request:get-parameter("L3", () )], $browse:levels[ not(. = ($L1,$L2)) ])[1],
        $L4 :=  (), (:  ($browse:levels[ . = request:get-parameter("L4", () )], $browse:levels[ not(. = ($L1,$L2,L3)) ])[1],  :)
        $all := ( $L1, $L2, $L3, $L4 ),
        $result := for $l at $pos in $all
             let $vector := fn:string-join(( 
                      for $v at $p in fn:subsequence( $all, 1, $pos )
                      return  local:level-signature( (), $v, $p, $v/@value-names)
                    ), ',')               
                   
             return element { QName("http://www.tei-c.org/ns/1.0",'level')}{
                attribute {'vector'}{ $vector},
                attribute {'pos'}{ $pos},
                attribute {'uuid'}{util:uuid()},
                $l/@*,
                string($l)
             }
(:       , $saved := cache:put($browse:cache, '$browse:LEVELS', $result)   :)            
       return $result  
;
 
declare variable $browse:URIs :=  (: combine multiple URI and multiple node-id :)                  
        let $u := for $i in (request:get-parameter("uri", () ),
                              request:get-parameter("entry-uri", () )) 
              return 
             
              element {  QName("http://www.tei-c.org/ns/1.0", 'URI' ) }{ 
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
                  return element { QName("http://www.tei-c.org/ns/1.0",'URI')}{
                      if( exists($u2/@name-node)) then attribute {'name-node'}{'true'} else (), 
                      element {'uri'}{ $i },
                      for $n in distinct-values($u2/node-id) 
                        return element {'node-id'}{ $n }
                  }
               )
            )
;   

declare variable $browse:CATEGORIES :=  (: combine multiple castegory types and names :)                  
    for $i in request:get-parameter("category", ()) 
          return 
          element { QName("http://www.tei-c.org/ns/1.0",'category')}{ 
              if(  contains($i,  $browse:delimiter-uri-node ) ) then (
                  element {'name'} {    fn:substring-before($i,$browse:delimiter-uri-node ) },
                  element {'key'}{ fn:substring-after($i, $browse:delimiter-uri-node )  }
             ) else if( contains($i,  $browse:delimiter-uri-nameNode ) ) then ( 
                  element {'name'} {    fn:substring-before($i, $browse:delimiter-uri-nameNode ) },                      
                  element {'value'}{ fn:substring-after($i,  $browse:delimiter-uri-nameNode )  }
              ) else (
                  element {'name'} { $i },
                  element {'key'} { '*' }
              )
          }
;   

declare function local:now() as xs:dateTime {   dateTime(current-date(), util:system-time() ) };



(: I have an error "Can not find the ICU4J library in the classpath com.ibm.icu.text.Normalizer " when using fn:normalize-unicode :)

declare function browse:heads-with-same-xmlID( $xml-id as xs:string* ) as node()*  { 
     for $i in browse-books:data-all((), true())//head[ .//@xml:id = $xml-id ] 
     let $s := fn:normalize-space(string( $i))
     order by string($i/@xml:id), $s
     return element {'head'}{
         attribute {'xml-id'}{ string( $i//@xml:id[1] ) },
         attribute {'node-id'}{ util:node-id($i) },
         attribute {'uri' }{ document-uri( root($i)) },
         $s 
     }     
};

declare function local:level-signature( $prexif as xs:string*, $level-name as xs:string, $pos as xs:int, $param-name as xs:string   ) {
    fn:string-join((
        $prexif,
       'L', $pos, $level-name ,
       for $p in request:get-parameter( $param-name, () ) order by $p return $p
       ), '-')
 };              

declare function browse:get-data-for-level( $data-from-prev-level as node()*, $level as node(), $root as xs:boolean  ) {
   let $data := if( $root ) then () else $data-from-prev-level,
       $cached := () (:  cache:get($browse:cache, $level/@vector)  :)
   return 
      if( $browse:use-cached-data = 'yes'  and exists($cached) ) then (
          $cached
      ) else (              
         let $result := if(      $level = 'names')   then browse-names:data-all(   $data, $root)
             else if( $level = 'entries') then browse-entries:data-all( $data, $root)
             else if( $level = 'books')   then browse-books:data-all(   $data, $root)                 
             else (),
             $saved := ( 
                         cache:put($browse:cache, $level/@vector, $result)
                         (:  $level/@vector - to reuse the save data but we need a mechanism to clear the cache
                             todo: save in a cache/vectors.xml a list of the vectors used with a timestamp 
                                   Then later use the timestamp and the vector id to:
                                       a) clear cached data in XX hours 
                                       b) refresh the cacheed data 
                         :)
                     ) 
         return $result
    )
};

declare function browse:get-data-for-level-filtered( $data as node()*, $level as node() ) {
    if(      $level = 'names')   then browse-names:data-filtered(   $data, $browse:URIs, $browse:CATEGORIES)
    else if( $level = 'entries') then browse-entries:data-filtered( $data, $browse:URIs, $browse:CATEGORIES)
    else if( $level = 'books')   then browse-books:data-filtered(   $data, $browse:URIs, $browse:CATEGORIES)                 
    else ()
};



declare function browse:levels-combo( $level as node(), $pos as xs:int ) as element(select) {
   <select name="L{$pos}" id="L{$pos}" style="width:100%">{
       for $L in $browse:LEVELS return 
       element {'option'}{
           if( $L is $level ) then (
                attribute {'selected'}{'selected'} 
           )else if( $pos = 2 and $L is $browse:LEVELS[1]) then (
                attribute {'disabled'}{'disabled'},
                attribute {'style'}{'display:none'}
           )else (),
           if($pos = 3 ) then (
              if( $L is $browse:LEVELS[1] or $L is $browse:LEVELS[2] ) then( 
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

(: example: local:change-element-ns-deep($x, "http://www.w3.org/1999/xhtml")  :)
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

declare function browse:section-parameters-combo( $section as element(titles)?, $level as node()? ) {
     let $has-groups := $section/group/@name
     let $same-xmlID := browse:heads-with-same-xmlID($section//@xml-id)
     
     return (
        <select id="{$level}" style="width:100%" 
           class="s-select {if( $browse:use-combo-plugin and count($section/group/title) < $browse:drop-combo-plugin-limit ) then 'chzn-select' else ()}" 
           name="{$section/@name}" title="No filters"  multiple="multiple">{
          if( exists( $has-groups )) then ( 
             for $g in $section/group return 
              <optgroup label="{ $g/@title}">{
                for $title in $g/title 
                  let $t :=  fn:normalize-space($title[not(@type='alt')][1])
                  let $same-xml-ids := fn:distinct-values($same-xmlID[ @xml-id = $title/@xml-id ][. != $t ])
                  return 
                     element {'option'}{ 
                        $title/@selected, 
                        $title/@value, 
                        $title/@title,
                        $title/@xml-id,                        
                        $t,
                        if( exists($same-xml-ids)) then 
                            concat('(', fn:string-join( $same-xml-ids, ', '), ')')
                        else ()
                     }
              }</optgroup>                 
          ) else ( 
           for $title in $section/group/title 
           let $t := fn:normalize-space($title[not(@type='alt')][1])
           let $same-xml-ids := fn:distinct-values( ($same-xmlID[@xml-id = $title/@xml-id ][ not(. = $t )], $title/*[@type='alt'])  )
           return 
             element {'option'}{ 
                $title/@selected, 
                $title/@value, 
                $title/@title, 
                $title/@xml-id,                      
                $t,
                if( exists($same-xml-ids)) then 
                    concat('(', fn:string-join( $same-xml-ids, ', '), ')')
                else () 
            }
          )
       }</select>
    )       
};

declare function browse:section-titles-combo(  $all-level-data as node(), $level as node()? ) {
  let $titles := if( empty($all-level-data) ) then 
          () 
       else typeswitch ($all-level-data[1] )
          case element(tei:TEI) return   browse-books:titles-list(   $all-level-data, $level, $browse:URIs, $browse:CATEGORIES )                
          case element(tei:div) return   browse-entries:titles-list( $all-level-data, $level, $browse:URIs, $browse:CATEGORIES )
          case element(tei:name) return browse-names:titles-list(    $all-level-data, $level, $browse:URIs, $browse:CATEGORIES )          
          default return <titles><title>no-titles</title></titles>			     
 
    return if( exists($titles)) then ( 
               browse:section-parameters-combo( $titles, $level )
           ) else ()
};


declare function browse:ajax-url( $level as node()?, $param as xs:string* ) as xs:string {
    fn:string-join((
      concat($browse:controller-url,'/browse-section?'),
      $param,
      if( exists( $level ) ) then (
          concat('level=', $level/@pos),         
          concat('uuid=', $level/@uuid ),  
          for $i at $pos in $browse:LEVELS return concat('L', $pos, '=', $i )
      ) else ()
    ),'&amp;')
};

declare function browse:ajax-loading-div( $level as node()?, $param as xs:string*, $id as xs:string ) as xs:string {
   <div id="{$level}-delayed" class="ajax-loaded loading-grey" url="{browse:ajax-url( $level, $param)}">Loading  { string($level/@title) }... </div> 
};


declare function browse:section-as-searchable-combo-generic( $data as node(), $level as node()?, $ajax-loaded as xs:boolean ) {                     
    <div class="grid_5">
		<div class="box L-box">
			<h2>{browse:levels-combo( $level,  $level/@pos ) }</h2>
			<div class="block L-block">{
    			    if( not($ajax-loaded) or number($level/@ajax-if-more-then) = -1 (: or count($data) <  number($level/@ajax-if-more-then)  :)   ) then (
                        browse:section-titles-combo(  $data, $level)
    			     ) else (
                        let $url := browse:ajax-url( $level, (
                                            concat('cache=', $level/@vector), 
                                            concat( 'section=L', $level/@pos, '-combo' ) 
                                    ))
     	     
    			        return <div id="{$level}-delayed" class="ajax-loaded loading-grey" url="{$url}">Loading  { string($level/@title) }... </div>   
    			     )                           
                }
                 <a href="#{$level}" class="combo-reset" combo2reset="{$level}" style="font-size:80%">Clear all filters for { string($level/@title)}.</a>
            </div>
		</div>
	</div>
};


declare function browse:level-boxes(){

    let  $data-1-all := browse:get-data-for-level(          (),          $browse:LEVELS[1], true() ),
         $data-1     := browse:get-data-for-level-filtered( $data-1-all, $browse:LEVELS[1]),
         
         $data-2-all := browse:get-data-for-level(          $data-1,     $browse:LEVELS[2], false() ),
         $data-2     := browse:get-data-for-level-filtered( $data-2-all, $browse:LEVELS[2]),
         
         $data-3-all := browse:get-data-for-level(          $data-2,     $browse:LEVELS[3], false() ),
         $data-3     := browse:get-data-for-level-filtered( $data-3-all, $browse:LEVELS[3]),
         
         $data-4-all := (),
         $data-4 := ()

   return 
   <form id="browseForm" action="{if( fn:contains(request:get-url(), '?')) then fn:substring-before(request:get-url(), '?') else request:get-url() }">{ 
    browse:section-as-searchable-combo-generic( $data-1-all, $browse:LEVELS[1], $browse:ajax-load ),
	browse:section-as-searchable-combo-generic( $data-2-all, $browse:LEVELS[2], $browse:ajax-load ),
	browse:section-as-searchable-combo-generic( $data-3-all, $browse:LEVELS[3], $browse:ajax-load),
	<span>
	   <!-- input type="checkbox" name="autoUpdate" id="autoUpdate">{
    	      if( request:get-parameter("autoUpdate", 'off' ) = 'on' ) then(
    	         attribute {'checked'}{'true'}
    	      )else()
    	   }</input>
    	   <span style="font-size:10px">Autoupdate</span>
	   <br/ -->
	   
	   <input type="submit" id="" value="Submit"/>
	</span>,
	<div class="clear"></div>	
   }</form>
};

declare function browse:entries-for-grid(){    
   let  
        $entries-level := $browse:LEVELS[.  = 'entries'],
        $data := cache:get( $browse:cache,   $entries-level/@vector ),
        $step1 := $data[ empty( $browse:URIs/node-id  ) or  util:node-id(.) = $browse:URIs/node-id and document-uri( root(.)) = $browse:URIs/uri  ],

        $filtered := if(  exists( $browse:CATEGORIES/name) ) then (
            let $names-with-values := if( exists( $browse:CATEGORIES/value) ) then 
                           for $n in $step1/descendant-or-self::tei:name[  empty(@key) and @type =  $browse:CATEGORIES/name ]
                           return if( exists( $browse:CATEGORIES[ name = $n/@type and value = fn:normalize-space($n )  ])) then 
                                     $n
                                  else ()
                        else ()                
               
            return  (if( exists($browse:CATEGORIES[key='*']) ) then (
                       $step1[  ./descendant-or-self::tei:name[ @type = $browse:CATEGORIES[key='*']/name ] ]
                    )else ())
                    |
                    (if( exists($browse:CATEGORIES[ key != '*']) ) then
                       $step1[  ./descendant-or-self::tei:name[ @key = $browse:CATEGORIES/key[not(. = '*') ] ]]
                    else ())                       
                    | 
                   $names-with-values/ancestor-or-self::tei:div[@type="entry"]   
       ) else 
              $step1,

        $vector :=  concat('grid-', $browse:LEVELS[ count($browse:LEVELS) ]/@vector), 
        $saved  :=  cache:put($browse:cache, $vector, $filtered)  
        
   return $filtered        
};

declare function browse:page-grid( $show-all as xs:boolean ){
   browse:page-grid( $show-all, true(), browse:entries-for-grid()  ) 
  
};

declare function browse:entiry-categories-listed( $e as node() ){
    for $c in browse-names:categories-list($e) 
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



declare function browse:page-grid( $show-all as xs:boolean, $ajax-loaded as xs:boolean, $grid-entities as node()*  ){ 
 	if( $show-all or exists($browse:URIs) or fn:exists($browse:CATEGORIES) ) then ( 	
 	 if( $ajax-loaded ) then (
 	         let $url := browse:ajax-url( (), (
                            'section=entity-grid',
                            concat('cache=grid-', $browse:LEVELS[ count($browse:LEVELS) ]/@vector)
                        ))
	         return
	             <div id="entity-grid" class="ajax-loaded loading-grey" section="entity-grid" 
	               url="{$browse:controller-url}/browse-section?section=entity-grid&amp;cache=grid-{$browse:LEVELS[ count($browse:LEVELS) ]/@vector}">Loading</div>   
	     ) else ( 	
         	<table class="browse-tbl" summary="Table summary" cellspacing="4" >		
        		<colgroup>
        			<col class="colA" width="20%"/>
        			<col class="colB" width="15%"/>
        			<col class="colB"/>
        			<col class="colC" />
        			<col class="colD" width="50%" />
        		</colgroup>
        		<thead>
        			<tr>
        				<th>Encyclopedia</th>
        				<th>Entry Title</th>
        				
        				<th>Subject</th>
        				<th>Categories</th>
        			</tr>
        		</thead>
        		<tbody>{
        			 for $e at $tr-pos in $grid-entities
                      let $root := $e/ancestor-or-self::tei:TEI,
        			      $uri  := document-uri( root($e)),
        			      $document-title := browse-books:title-extract($root//teiHeader/fileDesc/titleStmt, $browse:URIs),
        			      $node-id := util:node-id($e),
        			      $categories-number := browse-names:categories-number($e),        			      
        			      $alt-titles := browse-entries:alternative-titles($e)
        			 
        			 return <tr class="{ if( $tr-pos mod 2 = 0 ) then 'odd' else ()}">{
        				<td >{ string($document-title)}</td>,
        				<td  >{
                   				browse-entries:direct-link($e), 
        				        if( exists($alt-titles)) then concat(' (', fn:string-join( $alt-titles , ', '), ')') else() }</td>,
        				<td>{ string($e/@subtype )}</td>,
        				<td >{  
        				    
        				  if(  $categories-number >  $browse:categories-table-ajax-limit ) then (
                                 let $url := browse:ajax-url( (), (
                                                      concat('node-id=',  util:node-id($e) ), 
                                                      concat('uri=',   document-uri( root($e)) ),
                                                      concat('cat2get=', $categories-number   ),                                                      
                                                      'section=entry-cat-summary',
                                                      concat( 'id=td', $tr-pos ) 
                                              ))               	     
              			        return <div id="td{$tr-pos}" class="ajax-loaded loading-red" url="{$url}">Loading  { $categories-number } categories </div>           				       
        				  )else (
        				       browse:entiry-categories-listed( $e )
             				    
        				    
                            ) 
        				}</td>
        			}</tr>
        	    }</tbody>
        	</table>
    	)
    )else(
      <span>No entries to display</span>
       (: may be we can display a shot text to explain there will be a grid only when something is selected from the lists? :)
    )
};
