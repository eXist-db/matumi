xquery version "1.0";

import module namespace file="http://exist-db.org/xquery/file" at "java:org.exist.xquery.modules.file.FileModule";
import module namespace xdb="http://exist-db.org/xquery/xmldb";

declare function local:format-output($output) {
    if ($output//file:update) then
        <table>
            <tr>
                <th>Collection</th>
                <th>Resource</th>
            </tr>
        {
            for $update in $output//file:update
            return
               <tr>
                    <td>{$update/@collection/string()}</td>
                    <td>{$update/@name/string()}</td>
                    <td>{$update/file:error/string()}</td>
                </tr>
        }
        </table>
    else
        <p>All resources are up to date.</p>
};

(:    
    dateTime(current-date(),xs:time('00:01:00'))                         
    (util:system-time() -   request:get-parameter("start", ()) 
 :)
 
let $login :=      xdb:login( "/db", 'admin' , '')


let $startParam := request:get-parameter("start", '2011-08-20T00:00:00' )  
let $startTime := if (empty($startParam) or $startParam eq "") then () else $startParam 

let $collection := request:get-parameter("collection", '/db/matumi'  ) 
let $dir :=        request:get-parameter("dir", 'D:/eXist/apps/TEIXLingual' ) 

(:   let $output := file:sync($collection, $dir, $startParam )   :)
let $output := file:sync($collection, $dir, $startTime )

return element synch{
   element now { dateTime(current-date(), util:system-time() ) },
   element ts { dateTime(current-date(), util:system-time() ) + xs:dayTimeDuration('PT30M')  },
   $output
}
