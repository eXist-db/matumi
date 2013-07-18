xquery version "1.0";

module namespace browse="http://exist-db.org/xquery/apps/matumi/browse";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";

declare variable $browse:combo-ajax-load := 'yes' = request:get-parameter("ajax-combo", 'yes' );
declare variable $browse:grid-ajax-load := 'yes'  = request:get-parameter("ajax-grid", 'yes' );
declare variable $browse:use-cached-data := 'yes' = request:get-parameter("use-cached-data", 'yes' );
declare variable $browse:save-categories := 'yes' = request:get-parameter("save-categories", 'yes' );
declare variable $browse:refresh-categories := 'yes' = request:get-parameter("refresh-categories", 'yes' );
declare variable $browse:max-cat-summary-to-save := 10;

declare variable $browse:embeded-category-summary := false(); (: save the summary inside of the entry or the book :)

declare variable $browse:combo-plugin-in-use := true(); (: chzn-select :)
declare variable $browse:combo-plugin-drop-limit := 6000; (: switch to a clasic dropdown for better performance. To be fixed :)

declare variable $browse:grid-categories-page-size := 25;
declare variable $browse:grid-ajax-trigger := $browse:grid-categories-page-size * 2; (: :)
declare variable $browse:grid-categories-ajax-trigger := 20;

declare variable $browse:minutes-to-cache := 30;

declare variable $browse:cache-cleared := if( request:get-parameter("cache-reset", 'no' ) = 'yes') then cache:clear( session:get-id() ) else();
declare variable $browse:cache := cache:cache( session:get-id() );

declare variable $browse:controller-url := request:get-parameter("controller-url", 'missing-controller-url');
declare variable $browse:delimiter-uri-node := '___';
declare variable $browse:delimiter-uri-nameNode := '---';

declare variable $browse:levels := (
    <level value-names="uri" title="Books" ajax-if-more-then="-1" class="chzn-select">books</level>,             (: uri=/db/matumi/data/GSE-eng.xml :)
    <level value-names="entry-uri" title="Entries" ajax-if-more-then="50" class="chzn-select" >entries</level>, (:  uri=/db/matumi/data/GSE-eng.xml___3.2.2.2 :)
    <level value-names="category" title="Names" ajax-if-more-then="50" class="chzn-select" >names</level>
    (: , <level value-names="subject" title="Subjects">subject</level> :)
);

declare variable $browse:LEVELS := 
    let $L1 := ($browse:levels[ . = request:get-parameter("L1", () )], $browse:levels[1])[1],
        $L2 := ($browse:levels[ . = request:get-parameter("L2", () )], $browse:levels[ not(. = $L1) ])[1],
        $L3 := ($browse:levels[ . = request:get-parameter("L3", () )], $browse:levels[ not(. = ($L1,$L2)) ])[1],
        $L4 :=  (), (:  ($browse:levels[ . = request:get-parameter("L4", () )], $browse:levels[ not(. = ($L1,$L2,L3)) ])[1],  :)
        $all := ( $L1, $L2, $L3 ), (: , $L4 :)
        $result := for $l at $pos in $all
             let $vector := fn:string-join(( 
                      for $v at $p in fn:subsequence( $all, 1, $pos )
                      return  local:level-signature( (), $v, $p, $v/@value-names)
                    ), ',')               
                   
             return element { QName("http://www.tei-c.org/ns/1.0",'level')}{
                attribute {'vector'}{ $vector},
                attribute {'pos'}{ $pos},
                if( $pos = count($all)) then attribute {'last'}{'yes'} else(), 
                attribute {'uuid'}{util:uuid()},
                $l/@*,
                string($l)
             }
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

declare function browse:now() as xs:dateTime {   dateTime(current-date(), util:system-time() ) };

declare function local:level-signature( $prexif as xs:string*, $level-name as xs:string, $pos as xs:int, $param-name as xs:string   ) {
    fn:string-join((
        $prexif,
       concat('L', $pos, '=', $level-name) ,
       for $p in request:get-parameter( $param-name, () ) 
       order by $p          
       return for $i in $p 
              order by $i
              return $i
       ), '-')
 };              

