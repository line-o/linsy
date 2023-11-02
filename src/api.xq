xquery version "3.1";

declare namespace api="http://e-editiones.org/roasted/test-api";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace svg="http://www.w3.org/2000/svg";

import module namespace roaster="http://e-editiones.org/roaster";

import module namespace auth="http://e-editiones.org/roaster/auth";
import module namespace rutil="http://e-editiones.org/roaster/util";
import module namespace errors="http://e-editiones.org/roaster/errors";

import module namespace linsy-read = "//line-o.de/ns/linsy/read" at "content/read.xqm";

(:~
 : list of definition files to use
 :)
declare variable $api:definitions := ("api.json");
declare variable $api:systems-collection := "/db/apps/linsy/systems/";
declare variable $api:systems-resource-extension := ".xml";

declare function api:render($request as map(*)) {
    linsy-read:system($request?body/element())
};

declare function api:load-system($request as map(*)) {
    let $doc-name := $request?parameters?id || $api:systems-resource-extension
    let $doc-path := $api:systems-collection || $doc-name
    return
        if (doc-available($doc-path))
        then doc($doc-path)
        else error($errors:NOT_FOUND, "No system with id """ || $request?parameters?id || """ found")
};

declare function api:save-system($request as map(*)) {
    let $doc-name := $request?parameters?id || $api:systems-resource-extension
    return
        if (doc-available($api:systems-collection || $doc-name))
        then error($errors:BAD_REQUEST, "A system with id """ || $request?parameters?id || """ already exists.")
        else xmldb:store($api:systems-collection, $doc-name, $request?body)
};

declare function api:list-systems($request as map(*)) {
    array {
        for-each(xmldb:get-child-resources($api:systems-collection), function ($name as xs:string) as map(*) {
            map { "id": substring-before($name, $api:systems-resource-extension) }
        })
    }
};

(: end of route handlers :)

(:~
 : This function "knows" all modules and their functions
 : that are imported here 
 : You can leave it as it is, but it has to be here
 :)
declare function api:lookup ($name as xs:string) {
    function-lookup(xs:QName($name), 1)
};

(: util:declare-option("output:indent", "no"), :)
roaster:route($api:definitions, api:lookup#1)
