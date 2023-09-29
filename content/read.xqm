
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
    let $initial := map {
        "y": $render/initial/@y/number(),
        "x": $render/initial/@x/number(),
        "v": $render/initial/@v/number(),
        "o": $render/initial/@o/number(),
        "a": $render/initial/@a/number()
    }

    return render:svg($result, $initial, (), $viewBox, (), ())
};

declare function read:system($system-declaration as element(system)) as element() {
    let $iterations := xs:integer($system-declaration/@iterations)
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
