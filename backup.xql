import module namespace xdb="http://exist-db.org/xquery/xmldb";
declare option exist:serialize "media-type=text/xml";



        
let $jobs := 
    <jobs>
        <job>
           <param name="prefix" value="matumi_"/>,
           <param name="collection" value="/db/matumi"/>
        </job>
        <job>
           <param name="prefix" value="matumi-collection-xconf_"/>,
           <param name="collection" value="/db/system/config/db/matumi"/>
        </job>
        <!-- job>
           <param name="prefix" value="be-apps"/>,
           <param name="collection" value="/db/be/apps"/>
        </job>
        <job>
           <param name="prefix" value="be-users"/>,
           <param name="collection" value="/db/be/users"/>
        </job -->
    </jobs>
    


let $params :=
        <parameters>
            <param name="user" value="admin"/>
            <param name="password" value=""/>
            <param name="dir" value="backup/matumi/{substring(string(current-date()), 1, 10)}"/>            
            <param name="suffix" value=".zip"/>
            <param name="backup" value="yes"/>
		    <param name="incremental" value="no"/>
            <param name="zip-files-max" value="28"/>
        </parameters>


let $login :=      xdb:login( "/db", 'admin' , '')
        
return element backup {   
    for $job in $jobs/job return (
       let $done := system:trigger-system-task("org.exist.storage.BackupSystemTask", 
           element parameters{
              $params/*,
              $job/*        
           }
       )
       return  $job/param[@name='collection']    
    )
}
