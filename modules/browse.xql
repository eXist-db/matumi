xquery version "1.0";

declare namespace anno="http://exist-db.org/xquery/annotate";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare default element namespace "http://www.tei-c.org/ns/1.0";
declare copy-namespaces no-preserve, no-inherit;
declare boundary-space strip;


declare option exist:serialize "method=xhtml media-type=text/html omit-xml-declaration=yes indent=yes 
        doctype-public=-//W3C//DTD&#160;XHTML&#160;1.0&#160;Transitional//EN
doctype-system=http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";



(:
declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=no indent=yes";
:)

import module namespace dict="http://exist-db.org/xquery/dict" at "dict2html.xql";
import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

import module namespace browse="http://exist-db.org/xquery/apps/matumi/browse" at "browse.xqm";
import module namespace browse-books="http://exist-db.org/xquery/apps/matumi/browse-books" at "browse_books.xqm";
import module namespace browse-entries="http://exist-db.org/xquery/apps/matumi/browse-entries" at "browse_entries.xqm";
import module namespace browse-names="http://exist-db.org/xquery/apps/matumi/browse-names" at "browse_names.xqm";





(: Notes

Possible levels:

   books > entries > names
   books > names > entries

   entrirs > names > books
   entrirs > books > names
   
   names > entries > books
   names > books > entries
   
   
   For every level we have:
       - level element
       a) data set for this level - it comes from the previous level.
       b) data sub-set filtered out from a) by using specific values.
       c) list of values (titles) to display for this level created from b).
   Subset b) is passed to the next level


:)

declare function local:page-level-links(  ) {
    <table width="700"><tr>
        <td>
            <a href="?L1=books&amp;L2=entries&amp;L3=names">Books &gt; Entries &gt; Names</a><br/>
            <a href="?L1=books&amp;L2=names&amp;L3=entries">Books &gt; Names &gt; Entries </a><br/>
        </td>
        <td>
              <a href="?L1=entries&amp;L2=names&amp;L3=books">Entries &gt; Names &gt; Books</a><br/>
              <a href="?L1=entries&amp;L2=books&amp;L3=names">Entries &gt; Books &gt; Names</a><br/>
        </td>
        <td>
              <a href="?L2=entries&amp;L1=names&amp;L3=books">Names &gt; Entries &gt; Books</a><br/>
              <a href="?L1=names&amp;L2=books&amp;L3=entries">Names &gt; Books &gt; Entries</a><br/>
        </td>
      </tr>
    </table>
};







let $uri := request:get-parameter("uri", () ),
    $node-id := request:get-parameter("node-id", () ),
(:    $doc := if( exists($uri)) then  doc($uri) else (),
    $node := if( exists($doc) and exists($node-id)) then util:node-by-id($doc, $node-id) else (),
:)



(: we need: A. data nodes to extract the lower levels,
            B. List of titles(values) to display for this axon
:)


    $data-1 := 
          if(      $browse:L1 = 'books')   then  browse-books:data( (), $browse:URIs, 1)            
          else if( $browse:L1 = 'entries') then   browse-entries:data( (),  $browse:URIs, 1)  
          else if( $browse:L1 = 'names')   then   browse-names:data( (), $browse:URIs, 1)      
          else(),

    $data-2 := 
            if(      $browse:L2 = 'names')   then browse-names:data(   $data-1, $browse:URIs, 2)
            else if( $browse:L2 = 'entries') then browse-entries:data( $data-1, $browse:URIs, 2)
            else if( $browse:L2 = 'books')   then browse-books:data(   $data-1, $browse:URIs, 2)                 
            else (),

    $data-3 := 
            if(      $browse:L3 = 'names')   then browse-names:data(   $data-2, $browse:URIs, 3)
            else if( $browse:L3 = 'entries') then browse-entries:data( $data-2, $browse:URIs, 3)
            else if( $browse:L3 = 'books')   then browse-books:data(   $data-2, $browse:URIs, 3)                 
            else (),


     $titles-1 := if( empty($data-1) or empty($browse:L1)) then () else 
       typeswitch ($data-1[1] )
          case element(tei:TEI) return   browse-books:titles-list( $data-1, $browse:L1 )                
          case element(tei:div) return   browse-entries:titles-list( $data-1, $browse:L1 )
          case element(tei:name) return browse-names:titles-list( $data-1, $browse:L1 )          
          default return <titles><title>no-titles</title></titles>,
                   
     $titles-2 := if( empty($data-2) or empty($browse:L2)) then () else 
        typeswitch ($data-2[1] ) 
          case element(tei:TEI) return   browse-books:titles-list( $data-2, $browse:L2 )                
          case element(tei:div) return   browse-entries:titles-list( $data-2, $browse:L2 )
          case element(tei:name) return browse-names:titles-list( $data-2, $browse:L2 ) 
          default return <titles><title>no-titles</title>{ $data-2[1] }</titles>,
    
     $titles-3 := if( empty($data-3) or empty($browse:L3) ) then () else 
        typeswitch ($data-3[1] ) 
          case element(tei:TEI) return   browse-books:titles-list( $data-3, $browse:L3 )                
          case element(tei:div) return   browse-entries:titles-list( $data-3, $browse:L3 )
          case element(tei:name) return browse-names:titles-list( $data-3, $browse:L3 ) 
          default return <titles><title>no-titles</title>{ $data-2[1] }</titles>


    
(: xmlns="http://www.w3.org/1999/xhtml"  :)
return <html > 
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    { 
      browse:page-head(),
      element {'body'}{
         browse:page-content( 
              $titles-1,
              $titles-2,
              $titles-3
         )
     
        
      }
    }
</html>
    
