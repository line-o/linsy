xquery version "3.1";

import module namespace linsy = "//line-o.de/ns/linsy" at "linsy.xqm";

declare variable $algae-axiom := "A";
declare variable $algae-system := map {
    "A": "AB",
    "B": "A"
};

declare variable $fbtree-axiom := "0";
declare variable $fbtree-system := map {
    "1": "11",
    "0": "1[0]0",
    "[": "[",
    "]": "]"
};

declare variable $stochastic-fbtree-axiom := "0";
declare variable $stochastic-fbtree-system := map {
    "1": "11",
    "0": ( [0.5, "0"], [0.5, "1[0]0"] ),
    "[": "[",
    "]": "]"
};

(: create and iterate the algae system five times :)
linsy:deterministic(5, $algae-axiom, $algae-system),

(: create and iterate the binary tree systme 3 times :)
linsy:deterministic(3, $fbtree-axiom, $fbtree-system),

(: create and iterate the stochastic binary tree system 3 times :)
linsy:stochastic(3, $stochastic-fbtree-axiom, $stochastic-fbtree-system),

(: create iterator for a stochastic binary tree system and
 : re-use it with different seeds :)
let $system-iterator := linsy:create-stochastic($stochastic-fbtree-system)
return (
    linsy:iterate-stochastic($system-iterator, 4, $stochastic-fbtree-axiom, 0),
    linsy:iterate-stochastic($system-iterator, 4, $stochastic-fbtree-axiom, 1)
)
