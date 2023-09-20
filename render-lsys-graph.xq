xquery version "3.1";

import module namespace linsy = "//line-o.de/ns/linsy" at "linsy.xqm";
import module namespace render = "//line-o.de/ns/linsy/render" at "render.xqm";

declare default element namespace "http://www.w3.org/2000/svg";

declare function local:get-integer ($parameter, $default) {
    ( xs:integer(request:get-parameter($parameter, ())), $default )[1]
};

declare variable $local:iterations := local:get-integer("i", 8);

declare variable $local:initial := map {
    "x": local:get-integer("x", 0), 
    "y": local:get-integer("y", 6000),
    "v": local:get-integer("v", 16),
    "o": local:get-integer("o", 90),
    "a": local:get-integer("a", 45)
};


declare variable $fbtree-axiom := "0";
declare variable $stochastic-fbtree-system := map {
    "1": ([0.85, "11"], [0.15, "1"]),
    "0": ([0.475, "1[0]0"], [0.475, "11[0]0"], [0.05, "0"]),
    "[": (),
    "]": ()
};

declare variable $det-fbtree-system := map {
    "1": "11",
    "0": "1[0]0",
    "[": (),
    "]": ()
};

(: declare variable $local:segments := 8;
declare variable $local:orientation2rad := render:orientation2rad($local:segments); :)

declare function local:leaf ($state as map(*)) as map(*) {
    let $leaf :=
        <circle class="leaf" r="{$state?position?v div 1.5 }"
            cx="{$state?position?x}" cy="{$state?position?y}"/>

    return
        map:put($state, "elements", ($leaf, $state?elements))
};

declare function local:draw ($state as map(*), $next-symbol as xs:integer) { 
    switch(codepoints-to-string($next-symbol))
        case "0" return render:line($state) => local:leaf()
        case "1" return render:line($state)
        case "[" return render:push-stack($state) => render:turn-left()
        case "]" return render:pop-stack($state) => render:turn-right()
        default return error()
};

(: let $st := linsy:create-stochastic($stochastic-fbtree-system)
let $r := linsy:iterate-stochastic($st, xs:integer(request:get-parameter("i", "8")), $fbtree-axiom, ()) :)
let $r := linsy:deterministic($local:iterations, $fbtree-axiom, $det-fbtree-system)

return render:svg(
    $r,
    $local:initial,
    local:draw#2,
    "-3000 0 6000 6000",
    text {
        "
        .leaf { fill: green; }
        .axis { stroke: red; stroke-width: 1; }
        .line { stroke: black; stroke-width: 4; }
        .chunk { font: bold 9em monospace; fill: burlywood; }
        .a { font: 12em monospace; fill: brown; }
        "
    },
    (
        <rect x="-3000" y="0" width="6000" height="6000" fill="#eeeeee"/>,
        <text y="5150" x="-2800">{
            for $i in (0 to (string-length($r) idiv 80))
            let $start := $i * 80
            let $chunk := substring($r, $start + 1, 80)
            return <tspan class="chunk" dy="132" x="-2800">{$chunk}</tspan>
        }</text>,
        <text class="a" y="220" x="-2800">a = { $local:initial?a }</text>,
        <line x1="0" x2="0" y1="0" y2="6000" class="axis"/>,
        <line x1="-3000" x2="3000" y1="3000" y2="3000" class="axis"/>
    )
)
