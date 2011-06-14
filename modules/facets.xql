xquery version "1.0";

import module namespace facet="http://exist-db.org/xquery/fasets" at 'facets.xqm';
declare option exist:serialize "method=xml media-type=application/xml";

facet:get()