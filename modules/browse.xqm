xquery version "1.0";

module namespace browse="http://exist-db.org/xquery/apps/matumi/browse";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace util="http://exist-db.org/xquery/util";
import module namespace cache="http://exist-db.org/xquery/cache"     at "java:org.exist.xquery.modules.cache.CacheModule";


import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";
import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace browse-entries="http://exist-db.org/xquery/apps/matumi/browse-entries" at "browse_entries.xqm";
import module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names" at "browse_names.xqm";
import module namespace browse-subject="http://exist-db.org/xquery/apps/matumi/browse-subject"  at "browse_subject.xqm";
import module namespace browse-summary="http://exist-db.org/xquery/apps/matumi/browse-summary" at "browse_summary.xqm";

import module namespace browse-data="http://exist-db.org/xquery/apps/matumi/browse-data" at "browse_data.xqm";

(:
import module namespace browse-cache="http://exist-db.org/xquery/apps/matumi/cache" at "browse_cache.xqm";
import module namespace browse-config="http://exist-db.org/xquery/apps/matumi/browse-config" at "browse_config.xqm";
:)

declare variable $browse:combo-ajax-load := 'yes' = request:get-parameter("ajax-combo", 'yes' );
declare variable $browse:grid-ajax-load := 'yes'  = request:get-parameter("ajax-grid", 'yes' );
declare variable $browse:use-cached-data := 'yes' = request:get-parameter("use-cached-data", 'yes' );
declare variable $browse:save-categories := 'yes' = request:get-parameter("save-categories", 'yes' );
declare variable $browse:refresh-categories := 'yes' = request:get-parameter("refresh-categories", 'no' );

declare variable $browse:max-cat-summary-to-save := 20;

declare variable $browse:embeded-category-summary := false(); (: save the summary inside of the entry or the book :)

declare variable $browse:combo-plugin-in-use := true(); (: chzn-select :)
declare variable $browse:combo-plugin-drop-limit := 6000; (: switch to a clasic dropdown for better performance. To be fixed :)

declare variable $browse:grid-categories-page-size := 30;
declare variable $browse:grid-ajax-trigger := $browse:grid-categories-page-size; (: $browse:grid-categories-page-size :)
declare variable $browse:grid-categories-ajax-trigger := 10;

declare variable $browse:minutes-to-cache := 20;

declare variable $browse:cache-cleared := if( request:get-parameter("cache-reset", 'no' ) = 'yes') then cache:clear( session:get-id() ) else();
declare variable $browse:cache := cache:cache( session:get-id() );

declare variable $browse:controller-url := request:get-parameter("controller-url", 'missing-controller-url');
declare variable $browse:delimiter-uri-node := '___';
declare variable $browse:delimiter-uri-nameNode := '---';

declare variable $browse:base-time := browse-summary:base-time(false());

declare variable $browse:levels := (
    <level value-names="uri" title="Books" ajax-if-more-then="-1" class="chzn-select">books</level>,             (: uri=/db/matumi/data/GSE-eng.xml :)
    <level value-names="entry-uri" title="Entries" ajax-if-more-then="50" class="chzn-select" >entries</level>, (:  uri=/db/matumi/data/GSE-eng.xml___3.2.2.2 :)
    <level value-names="category" title="Names" ajax-if-more-then="50" class="chzn-select" >names</level>,
    <level value-names="subject" title="Subjects">subjects</level> 
);


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

declare variable $browse:SUBJECTS :=  (: combine multiple castegory types and names :)                  
    for $i in request:get-parameter("subject", ()) 
      return  element { QName("http://www.tei-c.org/ns/1.0",'subject')}{ 
          $i      
      }
;  

declare variable $browse:LEVELS := 
    let $L1 := ($browse:levels[ . = request:get-parameter("L1", () )], $browse:levels[1])[1],
        $L2 := ($browse:levels[ . = request:get-parameter("L2", () )], $browse:levels[ not(. = $L1) ])[1],
        $L3 := ($browse:levels[ . = request:get-parameter("L3", () )], $browse:levels[ not(. = ($L1,$L2)) ])[1],
        $L4 :=  ($browse:levels[ . = request:get-parameter("L4", () )], $browse:levels[ not(. = ($L1,$L2,$L3)) ])[1],  
        $all := ( $L1, $L2, $L3, $L4 ), (:  :)
        $result := for $l at $pos in $all
             return element { QName("http://www.tei-c.org/ns/1.0",'level')}{                
                attribute {'pos'}{ $pos},
                if( $pos = count($all)) then attribute {'last'}{'yes'} else(),
                attribute {'ts'}{ dateTime(current-date(), util:system-time())    },
                $l/@*,
                string($l)
             }
       return $result  
;
 
declare variable $browse:QUERIES :=  browse-data:queries-for-all-levels( $browse:LEVELS, $browse:URIs, $browse:CATEGORIES, $browse:SUBJECTS );

declare function browse:now() as xs:dateTime {   dateTime(current-date(), util:system-time() ) };



declare function browse:ajax-url( $level as node()?, $param as xs:string*, $controller-url as xs:string, $LEVELS ) as xs:string {
    fn:string-join((
      concat($controller-url,'/browse-section?'),
      for $i at $pos in $LEVELS return concat('L', $pos, '=', $i ),
      $param,
      if( exists( $level ) ) then (
          concat('level=', $level/@pos)
      ) else (),     
       for $L in $LEVELS return 
           for $p in request:get-parameter( $L/@value-names, () ) 
           order by $p          
           return concat($L/@value-names, '=', $p),
       concat('session=',session:get-id() ),
       concat('cache=', $level/@uuid) 
    ),'&amp;')
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

declare function browse:ajax-loading-div( $level as node()?, $param as xs:string*, $id as xs:string ) as xs:string {
   <div id="{$level}-delayed" class="ajax-loaded loading-grey" url="{browse:ajax-url( $level, $param, $browse:controller-url, $browse:LEVELS )}">Loading  { string($level/@title) }... </div> 
};

declare function browse:section-parameters-combo( $titles as element(titles)?, $level as node()?, $use-plugin as xs:boolean, $multiple as xs:boolean ) {
     let $has-groups := $titles/group/@name
     let $same-xmlID := browse-entries:heads-with-same-xmlID($titles//@xml-id)
     
     return (
        <select id="{$level}" style="width:100%" name="{$titles/@name}" title="No filters" >{
           $titles/@count,
           $titles/@total,
           $titles/@values,
           if( $multiple ) then attribute {'multiple'}{'true'} else(),
           if( $use-plugin and $browse:combo-plugin-in-use and count($titles/group/title) < $browse:combo-plugin-drop-limit ) then
               attribute {'class'}{ 'chzn-select' }
           else (),           
           if( exists( $has-groups )) then ( 
             for $g in $titles/group return 
              <optgroup label="{ $g/@title}">{                
                $g/@count,
                $g/total,
                $g/values,
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
           for $title in $titles/group/title 
           let $t := fn:normalize-space($title[not(@type='alt')][1])
           let $same-xml-ids := fn:distinct-values( ($same-xmlID[@xml-id = $title/@xml-id][ . != $t ], $title/*[@type='alt'])  )
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

declare function browse:section-as-searchable-combo-generic( $data as node(), $level as node()?, $ajax-loaded as xs:boolean ) {                     
    <div class="grid_4">
		<div class="box L-box">
			<h2>{browse:levels-combo( $level,  $level/@pos ) }</h2>
			<div class="block L-block">{
    			    if( not($ajax-loaded) or number($level/@ajax-if-more-then) = -1 (: or count($data) <  number($level/@ajax-if-more-then)  :)   ) then (
                        $data
    			     ) else (
                        let $url :=browse:ajax-url( $level, ( 'section=level-data-combo'), $browse:controller-url, $browse:LEVELS )     	     
    			        return <div id="{$level}-delayed" class="ajax-loaded loading-grey" url="{$url}">Loading  { string($level/@title) }... </div>   
    			     )                           
                }
                 <a href="#{$level}" class="combo-reset" combo2reset="{$level}" style="font-size:80%">Clear all filters for { string($level/@title)}.</a>
            </div>
		</div>
	</div>
};

declare function browse:section-titles-combo(  $level as node()? ) {
   let $titles := 
            if( $level = 'books')   then  browse-books:titles-list-fast(   $browse:QUERIES, $level, $browse:URIs, $browse:CATEGORIES )            
       else if( $level = 'entries') then  browse-entries:titles-list-fast( $browse:QUERIES, $level, $browse:URIs, $browse:CATEGORIES )
       else if( $level = 'names')   then  browse-names:titles-list-fast(   $browse:QUERIES, $level, $browse:URIs, $browse:CATEGORIES )    
       else if( $level = 'subjects') then  browse-subject:titles-list-fast(   $browse:QUERIES, $level, $browse:URIs, $browse:CATEGORIES, $browse:SUBJECTS )    
       else  <titles><title>no-titles for level { $level }</title></titles>			
 
    return if( exists($titles)) then ( 
               browse:section-parameters-combo( $titles, $level, true(), true() )
           ) else ()
};
 

declare function browse:level-boxes(){
   <form id="browseForm" action="{if( fn:contains(request:get-url(), '?')) then fn:substring-before(request:get-url(), '?') else request:get-url() }">
    
    { 
    (:     <input type="hidden" name="random" value="{util:uuid()}"/>  :)
    browse:section-as-searchable-combo-generic( browse:section-titles-combo(   $browse:LEVELS[1]), $browse:LEVELS[1], $browse:combo-ajax-load ),
	browse:section-as-searchable-combo-generic( browse:section-titles-combo(   $browse:LEVELS[2]), $browse:LEVELS[2], $browse:combo-ajax-load ),
	browse:section-as-searchable-combo-generic( browse:section-titles-combo(   $browse:LEVELS[3]), $browse:LEVELS[3], $browse:combo-ajax-load),
	browse:section-as-searchable-combo-generic( browse:section-titles-combo(   $browse:LEVELS[4]), $browse:LEVELS[4], $browse:combo-ajax-load),
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

(:
declare function browse:entries-for-grid(){    
   let  
        $entries-level := $browse:LEVELS[.  = 'entries'],
        $data := cache:get( $browse:cache,   $entries-level/@vector),
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

        $saved  :=  browse-cache:save( $browse:cache, $filtered, $entries-level/@vector, '-grid', $entries-level/@uuid )
   return $filtered        
};
:)

declare function browse:entries-fast( $level-name as xs:string ){    
    let $q := browse-data:strip-query(  $browse:QUERIES[@name= $level-name ]/tei:data-fitered )
    (: todo
       special cases: #all, #fullPath
        
    :)   
    return util:eval( $q[1] )        
};


declare function browse:page-grid( $show-all as xs:boolean ){
   let (: $check := browse-cache:check-cached-data(  $browse:minutes-to-cache ),  :)
       $data  :=  fn:subsequence(  browse:entries-fast( 'grid' ) , 1, $browse:grid-categories-page-size )    
   return  browse:page-grid( $show-all, $browse:grid-ajax-load, $data, false())   
};

declare function browse:page-grid( $show-all as xs:boolean, $ajax-loaded as xs:boolean, $grid-entities as node()*, $more as xs:boolean ){ 
       let $level := $browse:LEVELS[ .  = 'entries' ]
       let $url := browse:ajax-url( $level, (
                    'section=entity-grid',
                     if( $more ) then 'more=yes' else () 
                  ), $browse:controller-url, $browse:LEVELS)
                
 	   return if( $ajax-loaded  and count($grid-entities) > $browse:grid-categories-ajax-trigger ) then (
	         <div id="entity-grid" class="ajax-loaded loading-grey" section="entity-grid" copyURL="yes"  url="{ $url }">Loading</div>   
	     ) else ( 	
         	<table id="entryGrid" class="browse-tbl" summary="Table summary" cellspacing="4" >
         	  {  if( not($more) ) then attribute {'noMoreData'}{'yes'} else()  }
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
        			      $summary := $e/summary,
        			      $alt-titles := browse-entries:alternative-titles($e),
        			     (: $categories-number := number( ($summary/@count, browse-names:categories-number($e))[1]) :)
        			      $categories-number := number( ($summary/@names, $summary/@count, $browse:grid-categories-ajax-trigger + 2 )[1])
        			 
        			 return <tr class="{ if( $tr-pos mod 2 = 0 ) then 'odd' else ()}">{
        				<td >{ string($document-title)}</td>,
        				<td  >{
                   				browse-entries:direct-link($e), 
        				        if( exists($alt-titles)) then concat(' (', fn:string-join( $alt-titles , ', '), ')') else() }</td>,
        				<td>{ string($e/@subtype )}</td>,
        				<td class="cat-container collapsed" >{  
(:        				  if( $categories-number ) then( 
        				      (:  no categories :) '-'
        				  )else
:)
                           if( $categories-number  >  $browse:grid-categories-ajax-trigger  ) then (
                                 let $url := browse:ajax-url( (), (
                                                      concat('node-id=',  util:node-id($e) ), 
                                                      concat('cat-entry-uri=',   document-uri( root($e)) ),
                                                      concat('cat2get=', $summary/@values   ),                                                      
                                                      'section=entry-cat-summary',
                                                      concat( 'id=td', $tr-pos ) 
                                              ), $browse:controller-url, $browse:LEVELS)               	     
              			        return <div id="td{$tr-pos}" class="cat-container collapsed ajax-loaded loading-red" url="{$url}">Loading  { if( exists($summary/@count) ) then string($summary/@count) else '' } categories </div>           				       
        				  )else (
             				    browse-names:entiry-categories-listed( $e )
                            ) 
        				}</td>
        			}</tr>
        	    }</tbody>
        	</table>
    	)
};
