
module namespace read = "//line-o.de/ns/linsy/read";

import module namespace linsy = "//line-o.de/ns/linsy" at "linsy.xqm";
import module namespace render = "//line-o.de/ns/linsy/render" at "render.xqm";

declare variable $read:type-map := map {
    "deterministic": function ($iterations, $axiom, $system, $_) {
        linsy:deterministic($iterations, $axiom, $system)
    },
    "stochastic": linsy:stochastic#4,
    "parametric": function ($iterations, $axiom, $system, $seed) {
        linsy:parametric($iterations, $axiom, $system)
    }
};

declare function read:draw-function-from-module($qname as xs:QName, $draw as element(draw)) as function(*)? {
    (: try { :)
        let $import-options :=
            if (exists($draw/@location))
            then map { "location-hints" : $draw/@location/string() }
            else map { }
        let $load := function-lookup(xs:QName('fn:load-xquery-module'), 2)
        let $module := $load($draw/@ns/string(), $import-options)
        return 
            if (
                exists($module) and 
                map:contains($module, "functions") and
                map:contains($module?functions, $qname) and
                map:contains($module?functions?($qname), 2)
            ) then (
                $module?functions?($qname)?2
            ) else ()
    (: } catch * {
        ()
    } :)
};

declare function read:get-custom-draw-function ($draw as element(draw)) as function(*)? {
    let $qname := QName($draw/@ns/string(), $draw/@name/string())
    let $lookup-reference := function-lookup($qname, 2)

    let $reference :=
        if (empty($lookup-reference))
        then read:draw-function-from-module($qname, $draw)
        else $lookup-reference
    
    return
        if (empty($reference))
        then error((), "Function " || $qname || " not found")
        else $reference
};

declare function read:variable($variable-declaration as element(variable)) {
    if (exists($variable-declaration/option))
    then $variable-declaration/option ! ([ (./@weight/number(), 1)[1], ./string() ])
    else $variable-declaration/string()
};

declare function read:grammar($grammar-declaration as element()) as map(*) {
    let $uuu := ($grammar-declaration/variable, $grammar-declaration/terminal)
    return for-each($uuu, function ($el as element()) {
        map {
            $el/@symbol/string() :
                typeswitch ($el)
                case element(variable) return read:variable($el)
                default return ()
        }
    })
    => map:merge()
};

declare function read:render ($result as xs:string+, $render as element(render)) as element(svg) {
    let $viewBox := $render/@viewBox/string()
    let $state := map {
        "y": ($render/state/@y/number(), ())[1],
        "x": ($render/state/@x/number(), ())[1],
        "v": ($render/state/@velocity/number(), ())[1],
        "o": ($render/state/@orientation/number(), ())[1],
        "a": ($render/state/@angle/number(), ())[1],
        "s": ($render/state/@acceleration/number(), ())[1],
        "c": $render/state/@color/string()
    }

    let $draw-function :=
        if (exists($render/draw))
        then read:get-custom-draw-function($render/draw)
        else ()
    
    return render:svg($result, $state, $draw-function, $viewBox, $render/defs, $render/style, $render/background/element())
};

declare function read:system($system-declaration as element(grammar)) as element() {
    let $iterations :=
        if (exists($system-declaration/@iterations))
        then xs:integer($system-declaration/@iterations)
        else 3

    let $axiom := $system-declaration/axiom/string()

    let $grammar := $system-declaration/grammar
    let $system := read:grammar($grammar)
    let $type := ($grammar/@type/string(), "deterministic")[1]
    let $generator := $read:type-map?($type)

    let $seed :=
        if (empty($system-declaration/@seed))
        then ()
        else $system-declaration/@seed/number()

    let $result :=
        if (empty($generator))
        then error((), "unknown type " || $type)
        else if (empty($axiom))
        then error((), "axiom must be set but is '" || $axiom || "'")
        else $generator($iterations, $axiom, $system, $seed)

    return
        if (empty($system-declaration/render))
        then <code>{ string-join($result, "") }</code>
        else read:render($result, $system-declaration/render)
};
