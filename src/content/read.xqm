
module namespace read = "//line-o.de/ns/linsy/read";

import module namespace linsy = "//line-o.de/ns/linsy" at "linsy.xqm";
import module namespace render = "//line-o.de/ns/linsy/render" at "render.xqm";

declare variable $read:type-map := map {
    "deterministic": function ($iterations, $axiom, $system, $seed) {
        linsy:deterministic($iterations, $axiom, $system)
    },
    "stochastic": linsy:stochastic#4,
    "parametric": function ($iterations, $axiom, $system, $seed) {
        linsy:parametric($iterations, $axiom, $system)
    }
};

declare function read:get-custom-draw-function ($draw as element(draw)) as function(*)? {
    let $ns := $draw/@ns/string()
    let $loc := $draw/@location/string()
    let $name := $draw/@name/string()
    let $qname := QName($ns, $name)
    let $module := load-xquery-module($ns, map { "location-hints": $loc })
    
    let $reference := map:for-each($module?functions, function ($k, $v) {
        if ($k = $qname) then $v?2 else ()
    })
    
    return if (exists($reference)) then $reference else error()
};

declare function read:variable($variable-declaration as element(variable)) {
    if (exists($variable-declaration/option))
    then $variable-declaration/option ! ([
        (./@weight/number(), 1)[1],
        ./string()
    ])
    else $variable-declaration/string()
};

declare function read:grammar($grammar-declaration as element(grammar)) {
    for-each($grammar-declaration/(variable|terminal), function ($e) {
        map {
            $e/@symbol/string() :
                typeswitch ($e)
                case element(variable) return read:variable($e)
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

declare function read:system($system-declaration as element(system)) as element() {
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
        then error((), "unknown type " || $type, $system-declaration)
        else if (empty($axiom))
        then error((), "axiom must be set", $system-declaration)
        else $generator($iterations, $axiom, $system, $seed)

    return
        if (empty($system-declaration/render))
        then <code>{ string-join($result, "") }</code>
        else read:render($result, $system-declaration/render)
};
