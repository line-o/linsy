xquery version "3.1";

module namespace linsy = "//line-o.de/ns/linsy";

import module namespace prob = "//line-o.de/ns/prob" at "./prob.xqm";

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
) as xs:string+ {
    fold-left(
        1 to $iterations,
        linsy:split-string($axiom),
        linsy:create-deterministic($system))
};

declare
function linsy:create-deterministic(
    $system as map(*)
) as function(xs:string+, xs:integer) as xs:string+ {
    let $replacements := linsy:get-replacements($system)
    let $replace := map:get($replacements, ?)

    return
        function ($state as xs:string+, $iteration as xs:integer) as xs:string+ {
            for-each($state, $replace)
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
) as xs:string+ {
    linsy:stochastic($iterations, $axiom, $system, ())
};

(:~ Generate stochastic l-system with seeded random :)
declare function linsy:stochastic(
    $iterations as xs:integer,
    $axiom as xs:string,
    $system as map(*),
    $seed as xs:double?
) as xs:string+ {
    fold-left(1 to $iterations,
        map {
            "state": linsy:split-string($axiom), 
            "random": random-number-generator($seed)
        },
        linsy:create-stochastic($system)
    )
    ?state
};

declare function linsy:iterate-stochastic (
    $system-iter as function(*),
    $iterations as xs:integer,
    $axiom as xs:string,
    $seed as xs:double?
) as xs:string+ {
    fold-left(1 to $iterations,
        map {
            "state": linsy:split-string($axiom),
            "random": random-number-generator($seed)
        },
        $system-iter
    )
    ?state
};

declare
function linsy:create-stochastic($system as map(*)) as function(map(*), xs:integer) as map(*) {
    let $replacements :=
        map:for-each($system, linsy:get-stochastic-replacements#2)
        => map:merge()
    
    let $replace :=
        function ($acc as array(*), $next-symbol as xs:string) as array(*) {
            let $f := $replacements?($next-symbol)
            return [ ( $acc?1, $f($acc?2?number) ), $acc?2?next() ]
        }

    return
        function ($result as map(*), $iteration as xs:integer) as map(*) {
            let $new-state := fold-left($result?state, [ (), $result?random ], $replace)
            return
                map {
                    "state": $new-state?1,
                    "random": $new-state?2?next()
                }
        }
};

declare function linsy:get-stochastic-replacements ($match as xs:string, $rule as item()*) as map(xs:string, function(xs:string) as xs:string+) {
    map {
        $match : typeswitch($rule)
            case xs:string return
                function($_) { linsy:split-string($rule) }
            (: case empty-sequence() return
                function($_) { $match } :)
            case array(*)+ return
                prob:select-by-p(
                    prob:prepare-options($rule, linsy:prep-rule#2),
                    ?
                )
            default return 
                if (empty($rule)) (: $match is a terminal :)
                then function($_) { $match }
                else error((), "Unsupported type for rule " || $rule)
    }
};


(: ------------- UTIL ----------------- :)

declare function linsy:prep-rule ($adjusted-weight as xs:double, $rule as array(*)) as array(*) {
    [ $adjusted-weight, linsy:split-string($rule?2) ]
};

declare function linsy:split-string($string as xs:string) as xs:string+ {
    string-to-codepoints($string)
        ! codepoints-to-string(.)
};

declare %private
function linsy:get-replacements($system as map(*)) as map(*) {
    map:for-each($system, function ($k, $v) {
        map { $k : if ($v) then linsy:split-string($v) else $k }
    })
    => map:merge()
};

(: ------------- WIP ----------------- :)

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


declare %private
function linsy:create-parametric(
    $system as map(*)
) as function(xs:string, xs:integer) as xs:string {
    "not implemented yet"
    (: let $parse := linsy:get-parser($system)
    let $replace := map:get($system, ?)

    return
        function ($state as xs:string, $iteration as xs:integer) {
            $parse($state) => for-each($replace) => string-join("")
        } :)
};
