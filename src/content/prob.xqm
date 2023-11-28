module namespace prob = "//line-o.de/ns/prob";

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace array = "http://www.w3.org/2005/xpath-functions/array";

(: select by p from prepared sequence of options :)
declare
function prob:select-by-p($options as array(*)+, $p as xs:double) as item()* {
    fold-left($options, (),
        prob:select(?, ?, $p)
    )?2
};

(: This is just a convenience function :)
declare
function prob:prepare-and-select($options as array(*)+, $p as xs:double) as item()* {
    prob:prepare-options($options)
    => prob:select-by-p($p)
};

(: prepare a sequence of options :)
declare
function prob:prepare-options ($options as array(*)+) as array(*)+ {
    prob:prepare-options($options, prob:adjust-option#2)
};

(: if you want to tweak option adjustment :)
declare
function prob:prepare-options (
    $options as array(*)+,
    $adjust as function(xs:double, array(*)) as array(*)
) as array(*)+ {
    for $adjusted-weight at $pos in prob:adjust-weights($options?1) 
    return array:put($options[$pos], 1, $adjusted-weight)
};

(: ---- helper functions ---- :)

declare %private
function prob:adjust-weights ($weights as xs:numeric*) as xs:numeric* {
    fold-left($weights,
        map{ "sum": 0, "adjusted": () },
        prob:adjust-weight(?, ?, 1.0 div sum($weights))
    )
    ?adjusted
};

(:~
 : either there is a result or the p is too small: move on to the next
 :)
declare %private
function prob:select($result as array(*)?, $next as array(*), $p as xs:double) as array(*)? {
    if (empty($result) and $next?1 >= $p)
    then $next
    else $result 
};

declare %private
function prob:adjust-weight($acc as map(*), $next-weight as xs:double, $factor as xs:double) as map(*) {
    let $sum := $acc?sum + $next-weight
    return map{
        "sum": $sum,
        "adjusted": ($acc?adjusted,
            round-half-to-even($sum * $factor, 17)) (: get rid of floating point problems :)
    }
};

declare %private
function prob:adjust-option ($adjusted-weight as xs:double, $option as array(*)) as array(*) {
    array:put($option, 1, $adjusted-weight)
};
