xquery version "3.1";

module namespace render = "//line-o.de/ns/linsy/render";

import module namespace linsy = "//line-o.de/ns/linsy" at "linsy.xqm";

declare default element namespace "http://www.w3.org/2000/svg";

declare variable $render:one-deg := math:pi() div 180.0;

(:~
 : the default initial position
 :)
declare variable $render:default-initial-position := map {
    "x": 0, "y": 0, (: the root of the coordinate system :)
    "o": 0, (: orientation in degrees (or segments) :)
    "v": 1, (: velocity in coordinate units :)
    "a": 45, (: angle in degrees :)
    "s": 1,  (: speed increase :)
    "c": ()
};

(:~
 : alternative approach to rotation based on segments of a circle
 :)
declare function render:orientation2rad ($amount as xs:integer) {
    let $segment-rad := (2 div $amount) * math:pi()
    let $segments := for-each(0 to ($amount - 1), function ($i as xs:integer) {
            map { $i : $i * $segment-rad } })
    return map:merge($segments)
};

declare function render:circle ($state) {
    let $leaf := element circle {
        attribute class { "circle" },
        attribute r { $state?position?v },
        attribute cx { $state?position?x },
        attribute cy { $state?position?y },
        if ($state?position?c) then attribute fill {$state?position?c} else ()
    }

    return
        map:put($state, "elements", ($leaf, $state?elements))
};

declare function render:next-pos($position as map(*)) as map(*) {
    let $radians := $position?o * $render:one-deg

    return map {
        "x": $position?x + $position?v * math:cos($radians),
        "y": $position?y - $position?v * math:sin($radians),
        "o": $position?o,
        "v": $position?v,
        "a": $position?a,
        "s": $position?s,
        "c": $position?c
    }
};

declare function render:line-from-to ($p1 as map(*), $p2 as map(*)) as element(line) {
    <line class="line"
        x1="{ $p1?x }" x2="{ $p2?x }"
        y1="{ $p1?y }" y2="{ $p2?y }"
        stroke="{$p2?c}" stroke-width="{math:sqrt($p1?v)}"/>
};

declare function render:move ($state as map(*)) as map(*) {
    map {
        "position": render:next-pos($state?position),
        "stack": $state?stack,
        "elements": $state?elements
    }
};

declare function render:line ($state as map(*)) as map(*) {
    let $next := render:next-pos($state?position)
    let $line := render:line-from-to($state?position, $next)

    return
        map {
            "position": $next,
            "stack": $state?stack,
            "elements": ($line, $state?elements)
        }
};

declare function render:push-stack ($state as map(*)) as map(*) {
    map {
        "position": $state?position,
        "stack": ($state?position, $state?stack),
        "elements": $state?elements
    }
};
declare function render:pop-stack ($state as map(*)) as map(*) {
    map {
        "position": head($state?stack),
        "stack": tail($state?stack),
        "elements": $state?elements
    }
};

declare function render:turn-left ($state as map(*)) as map(*) {
    map {
        "position": map:put($state?position, "o", 
            ($state?position?o + $state?position?a) mod 360),
        "stack": $state?stack,
        "elements": $state?elements
    }
};

declare function render:turn-right ($state as map(*)) as map(*) {
    map {
        "position": map:put($state?position, "o",
            (360 + $state?position?o - $state?position?a) mod 360),
        "stack": $state?stack,
        "elements": $state?elements
    }
};

declare function render:increase-velocity ($state as map(*)) as map(*) {
    map {
        "position": map:put($state?position, "v", ($state?position?v * $state?position?s)),
        "stack": $state?stack,
        "elements": $state?elements
    }
};

declare function render:decrease-velocity ($state as map(*)) as map(*) {
    map {
        "position": map:put($state?position, "v", ($state?position?v div $state?position?s)),
        "stack": $state?stack,
        "elements": $state?elements
    }
};

(:~
 : "standard" actions taken from inkscape's L-System renderer
 : added: "<" and ">" to modify velocity
 :)
declare function render:symbol ($state as map(*), $next-symbol as xs:integer) as map(*) { 
    switch($next-symbol)
        case "A" case "B" case "C" case "D" case "E" case "F"
            return render:line($state)
        case "G" case "H" case "I" case "J" case "K" case "L"
            return render:move($state)
        case "@" return render:move($state)=>render:circle()
        case "-" return render:turn-left($state)
        case "+" return render:turn-right($state)
        case "[" return render:push-stack($state)
        case "]" return render:pop-stack($state)
        case "<" return render:increase-velocity($state)
        case ">" return render:decrease-velocity($state)
        default return error(xs:QName("linsy:unknown-symbol"), $next-symbol)
};

declare function render:system ($system-result as xs:string+, $initial-position as map(*)) as element()* {
    render:system($system-result, $initial-position, ())
};

declare function render:system ($system-result as xs:string+, $initial-position as map(*)?, $draw-function as (function(map(*), xs:integer) as map(*))?) as element()* {
    fold-left(
        $system-result,
        map{
            "stack":(), "elements":(), 
            "position": map:merge(( $initial-position, $render:default-initial-position ), map{"duplicates": "use-first"})
        },
        ($draw-function, render:symbol#2)[1]
    )?elements
};

declare function render:svg ($result, $initial, $draw, $view-box, $style as text()?, $background as element()*) as element(svg) {
    render:svg($result, $initial, $draw, $view-box, (), <style>{ $style }</style>, $background)
};

declare function render:svg ($result, $initial, $draw, $view-box, $defs as element()?, $style as element()?, $background as element()*) as element(svg) {
    <svg viewBox="{$view-box}" width="100%" height="100%">
        { $defs, $style }
        <g id="background">{ $background }</g>
        <g id="system">{ render:system($result, $initial, $draw) }</g>
    </svg>
};

