
module namespace read = "//line-o.de/ns/linsy/read";

import module namespace linsy = "//line-o.de/ns/linsy" at "linsy.xqm";

declare variable $read:type-map := (
    "deterministic": function ($iterations, $axiom, $system, $seed) {
        linsy:deterministic($iterations, $axiom, $system)
    },
    "stochastic": linsy:stochastic#4,
    "parametric": function ($iterations, $axiom, $system, $seed) {
        linsy:parametric($iterations, $axiom, $system)
    }
);

declare function read:symbol($symbol-declaration as element(symbol)) {
    if (exists($symbol-declaration/option))
    then $symbol-declaration/option ! [ xs:double(./@probability), ./string() ]
    else $symbol-declaration/string()
};

declare function read:grammar($grammar-declaration as element(grammar)) {
    for-each($grammar-declaration/(symbol|terminal), function ($e) {
        map {
            $e/@match/string() :
                typeswitch ($e)
                case element(symbol) return read:symbol($e)
                default return ()
        }
    })
    => map:merge()
};

declare function read:system($system-declaration as element(system)) {
    let $system := read:grammar($system-declaration/grammar)
    let $axiom := $system-declaration/@axiom/string()
    let $iterations := xs:integer($system-declaration/@iterations)
    let $seed := xs:double($system-declaration/@seed)
    let $type := $system-declaration/grammar/@type/string()
    let $generator := $read:type-map($type)
    return
        if ($generator)
        then $generator($iterations, $axiom, $system, $seed)
        else error((), "unknown type " || $type)
};
