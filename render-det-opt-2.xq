xquery version "3.1";

import module namespace linsy = "//line-o.de/ns/linsy" at "content/linsy.xqm";
import module namespace render = "//line-o.de/ns/linsy/render" at "content/render.xqm";

declare default element namespace "http://www.w3.org/2000/svg";

declare function local:get-integer ($parameter, $default) {
    ( xs:integer(request:get-parameter($parameter, ())), $default )[1]
};

declare variable $local:iterations := local:get-integer("i", 8);
declare variable $local:velocity := local:get-integer("v", 16);

declare variable $local:initial := map {
    "x": local:get-integer("x", 0), 
    "y": local:get-integer("y", 5180),
    "v": $local:velocity,
    "o": local:get-integer("o", 90),
    "a": local:get-integer("a", 45)
};

declare variable $local:sw := 6 * ($local:velocity div 125);

declare variable $local:style := text {
"
.leaf { fill: rgba(90,222,100, .5); }
.axis { stroke: red; stroke-width: 1; }
.line {
    stroke: rgb(90,40,50); 
          stroke-width: " || $local:sw || "; }
.line-0 { stroke-width: " || $local:sw * 2 || "; }
.line-1 { stroke-width: " || $local:sw * 3 || "; }
.line-2 { stroke-width: " || $local:sw * 5 || "; }
.line-3 { stroke-width: " || $local:sw * 8 || "; }
.line-4 { stroke-width: " || $local:sw * 13 || "; }
.line-5 { stroke-width: " || $local:sw * 21 || "; }
.line-6 { stroke-width: " || $local:sw * 34 || "; }
.line-7 { stroke-width: " || $local:sw * 55 || "; }
.line-8 { stroke-width: " || $local:sw * 89 || "; }
.line-9 { stroke-width: " || $local:sw * 144 || "; }
.line-10 { stroke-width: " || $local:sw * 233 || "; }
.line-11 { stroke-width: " || $local:sw * 377 || "; }
.line-12 { stroke-width: " || $local:sw * 610 || "; }
.line-13 { stroke-width: " || $local:sw * 987 || "; }
.line-14 { stroke-width: " || $local:sw * 1597 || "; }
.chunk { font: bold 9em monospace; fill: burlywood; }
.a { font: 12em monospace; fill: brown; }
"
};


declare variable $fbtree-axiom := "0";
declare variable $det-fbtree-system := map {
    "1": "2",
    "2": "3",
    "3": "4",
    "4": "5",
    "5": "6",
    "6": "7",
    "7": "8",
    "8": "9",
    "9": "a",
    "a": "b",
    "b": "c",
    "c": "d",
    "d": "e",
    "e": "f",
    "0": "10]0",
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

declare function local:change-v ($position as map(*), $new-v) as map(*) {
    map:put($position, "v", $new-v)
};

declare function local:render-line-element ($p1 as map(*), $p2 as map(*), $age) as element(line) {
    <line class="line line-{$age}"
        x1="{ $p1?x }" x2="{ $p2?x }"
        y1="{ $p1?y }" y2="{ $p2?y }" />
};

declare function local:line ($state as map(*), $age as xs:integer) as map(*) {
    let $current-v := $state?position?v
    (: create temporary state with higher velocity :)
    let $next := render:next-pos(
        local:change-v($state?position, $current-v * math:pow(2, $age)))
    (: draw line using temporary state :)
    let $line := local:render-line-element($state?position, $next, $age)
    (: return new state with new element and velocity reset :)
    return 
        map {
            "position": local:change-v($next, $current-v),
            "stack": $state?stack,
            "elements": ($line, $state?elements)
        }
};

declare function local:draw ($state as map(*), $next-symbol as xs:string) { 
    switch($next-symbol)
        case "0" return render:line($state) => local:leaf()
        case "]" return render:pop-stack($state) => render:turn-right()
        case "1" return local:line($state, 0) => render:push-stack() => render:turn-left()
        case "2" return local:line($state, 1) => render:push-stack() => render:turn-left()
        case "3" return local:line($state, 2) => render:push-stack() => render:turn-left()
        case "4" return local:line($state, 3) => render:push-stack() => render:turn-left()
        case "5" return local:line($state, 4) => render:push-stack() => render:turn-left()
        case "6" return local:line($state, 5) => render:push-stack() => render:turn-left()
        case "7" return local:line($state, 6) => render:push-stack() => render:turn-left()
        case "8" return local:line($state, 7) => render:push-stack() => render:turn-left()
        case "9" return local:line($state, 8) => render:push-stack() => render:turn-left()
        case "a" return local:line($state, 9) => render:push-stack() => render:turn-left()
        case "b" return local:line($state, 10) => render:push-stack() => render:turn-left()
        case "c" return local:line($state, 11) => render:push-stack() => render:turn-left()
        case "d" return local:line($state, 12) => render:push-stack() => render:turn-left()
        case "e" return local:line($state, 13) => render:push-stack() => render:turn-left()
        case "f" return local:line($state, 14) => render:push-stack() => render:turn-left()
        default return error((), "---- " || $next-symbol || " ----")
};

declare function local:render ($r) {
    render:svg(
        $r,
        $local:initial,
        local:draw#2,
        "-3000 0 6000 6000",
        $local:style,
        (
            <rect x="-3000" y="0" width="6000" height="6000" fill="#fafaff"/>,
            <text y="5150" x="-2800">{
                for $i in (0 to (count($r) idiv 80))
                let $start := $i * 80
                let $chunk := subsequence($r, $start + 1, 80)
                return <tspan class="chunk" dy="132" x="-2800">{string-join($chunk, "")}</tspan>
            }</text>,
            <text class="a" y="220" x="-2800">a = { $local:initial?a }</text>
            (: <line x1="0" x2="0" y1="0" y2="6000" class="axis"/>,
            <line x1="-3000" x2="3000" y1="3000" y2="3000" class="axis"/> :)
        )
    )
};

linsy:deterministic($local:iterations, $fbtree-axiom, $det-fbtree-system)
=> local:render()
