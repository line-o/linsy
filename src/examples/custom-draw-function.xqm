module namespace custom = "//line-o.de/ns/linsy/render/custom";

import module namespace render = "//line-o.de/ns/linsy/render" at "../content/render.xqm";

declare function custom:draw ($state as map(*), $next-symbol as xs:string) { 
    switch($next-symbol)
        case "A" return custom:l($state)
        case "B" return render:line($state)
        case "-" return render:turn-left($state)
        case "+" return render:turn-right($state)
        case "&gt;" return render:decrease-velocity($state)
        case "&lt;" return render:increase-velocity($state)
        default return error()
};

declare function custom:l ($state as map(*)) {
    let $next := render:next-pos($state?position)
    let $line := custom:use($state?position)

    return
        map {
            "position": $next,
            "stack": $state?stack,
            "elements": ($line, $state?elements)
        }
};

declare function custom:use ($position as map(*)) {
         (: scale({$position?v} {$position?v})" :)
    <use href="#l"  
        transform="translate({$position?x} {$position?y}) scale({$position?v} {$position?v}) rotate({$position?o})"
        fill="{$position?c}" />
};
