xquery version "3.1";

module namespace linsy = "//line-o.de/ns/linsy";

(:~
 : Generate the n-th iteration of an l-system in xquery
 : System grammars are described as a map of
 : - symbols with a replacement ("A" : "AB")
 : - and constants ("[" : ())
 :
 : Stochastic grammars can have replacements with a list of probable outcomes.
 : A sequence of entries with probability and replacement. Probabilites
 : should add up to 1.0 but the system will be generated even if this is not the
 : case.
 : Examples:
 : - 50% chance of one of the choices : ( [0.5, "0"], [0.5, "1[0]0"] )
 : - ~33% chance of one of the choices : ( [1 div 3, "0"], [1 div 3, "["], [1 div 3,"1[0]0"]
 :
 : More examples and the theory behind it can be found at
 : https://en.wikipedia.org/wiki/L-system
 :)

(:~
 : Generate deterministic l-system 
 : 
 : Example: Generate three iterations of the algae system
 :
    linsy:deterministic(3, "A", map { "A": "AB", "B": "A" })
 : 
 :)
declare function linsy:deterministic(
    $iterations as xs:integer,
    $axiom as xs:string,
    $system as map(*)
) as xs:string {
    fold-left(1 to $iterations, $axiom, linsy:create-deterministic($system))
};

declare function linsy:iterate-stochastic (
    $system-iter as function(*),
    $iterations as xs:integer,
    $axiom as xs:string,
    $seed as xs:double?
) {
    fold-left(1 to $iterations,
        map { "state": $axiom, "random": random-number-generator($seed) },
        $system-iter
    )?state
};

declare function linsy:parametric(
    $iterations as xs:integer,
    $axiom as xs:string,
    $system as map(*)
) as xs:string {
    linsy:parametric($iterations, $axiom, $system, ())
};

(:~ Generate stochastic l-system with seeded random :)
declare function linsy:parametric(
    $iterations as xs:integer,
    $axiom as xs:string,
    $system as map(*),
    $seed as xs:double?
) as xs:string {
    fold-left(1 to $iterations,
        map { "state": $axiom },
        linsy:create-parametric($system)
    )?state
};

declare
function linsy:create-deterministic(
    $system as map(*)
) as function(xs:string, xs:integer) as xs:string {
    let $parse := linsy:get-parser($system)
    let $replace := function ($symbol as xs:string) {
        ($system?($symbol), $symbol)[1]
    }

    return
        function ($state as xs:string, $iteration as xs:integer) {
            $parse($state) => for-each($replace) => string-join("")
        }
};

(:~
 : Generate stochastic l-system
 : 
 : Example: Generate 4 iterations of the stochastic fractal binary tree system
 :
    import module namespace linsy = "//line-o.de/ns/linsy";
    linsy:stochastic(4, "0", map {
        "1": "11", "[": (), "]": (),
        "0": ([0.5,"0"], [0.5,"1[0]0"])
    })
 :)
declare function linsy:stochastic(
    $iterations as xs:integer,
    $axiom as xs:string,
    $system as map(*)
) as xs:string {
    linsy:stochastic($iterations, $axiom, $system, ())
};

(:~ Generate stochastic l-system with seeded random :)
declare function linsy:stochastic(
    $iterations as xs:integer,
    $axiom as xs:string,
    $system as map(*),
    $seed as xs:double?
) as xs:string {
    fold-left(1 to $iterations,
        map { "state": $axiom, "random": random-number-generator($seed) },
        linsy:create-stochastic($system)
    )?state
};

declare %private
function linsy:create-parametric(
    $system as map(*)
) as function(xs:string, xs:integer) as xs:string {
    let $parse := linsy:get-parser($system)
    let $replace := map:get($system, ?)

    return
        function ($state as xs:string, $iteration as xs:integer) {
            $parse($state) => for-each($replace) => string-join("")
        }
};

declare
function linsy:create-stochastic($system as map(*)) as function(xs:string, xs:integer) as xs:string+ {
    let $parse := linsy:get-parser($system)
    let $replacements := map:for-each($system, function($match, $rule) {
        map { 
            $match :
            typeswitch($rule)
                case array(*)+
                    return linsy:select-by-probability($rule, ?)
                case xs:string return function($_) { $rule }
                case empty-sequence() return function($_) { $match }
                default return error()
        }
    }) => map:merge()
    
    let $replace :=
        function ($result as xs:string, $symbol as xs:string) as array(*) {
            [
                $result?1 || $replacements($symbol)($result?2?number),
                $result?2?next()
            ]
        }

    return
        function ($result as map(*), $iteration as xs:integer) as map(*) {
            let $new-state := $parse($result?state)
                    => fold-left([ "", $result?random ], $replace)
            return
                map {
                    "state": $new-state?1,
                    "random": $new-state?2?next()
                }
        }
};

declare %private
function linsy:select-by-probability($probabilites as array(*)+, $random as xs:double) as xs:string {
    fold-left($probabilites, [ (), 0, $random ], linsy:probability-reducer#2)?1
};

declare %private
function linsy:probability-reducer($result as array(*), $next as array(*)) {
    if (exists($result?1)) then $result
    else
        let $sum := $result?2 + $next?1
        let $match := if ($sum > $result?3) then $next?2 else ()
        return [ $match, $sum, $result?3 ]
};

declare %private
variable $linsy:special-regex-characters := (
    ".", "?", "*", "+", "-", "|", "\",
    "[", "]", "(", ")", "{", "}"
);

declare %private
function linsy:get-parser($system as map(*)) as function(xs:string) as element()* {
    let $grammar := map:keys($system) ! (
        if (. = $linsy:special-regex-characters)
        then "\" || .
        else .
    )
    let $regex := string-join($grammar, "|")

    return
        function ($state as xs:string) as element()* {
            analyze-string($state, $regex)/element()
        }
};

declare %private
function linsy:get-parametric-parser($system as map(*)) as function(xs:string) as element()* {
    let $grammar := map:keys($system) ! (
        if (. = $linsy:special-regex-characters)
        then "\" || .
        else .
    )
    let $regex := string-join($grammar, "|")

    return
        function ($state as xs:string) as element()* {
            analyze-string($state, $regex)/element()
        }
};
