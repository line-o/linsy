let $algae := document {
    <a>
        <a>
            <a>
                <a>
                    <a/>
                    <b/>
                </a>
                <b>
                    <a/>
                </b>
            </a>
            <b>
                <a>
                    <a/>
                    <b/>
                </a>
            </b>
        </a>
        <b>
            <a>
                <a>
                    <a/>
                    <b/>
                </a>
                <b>
                    <a/>
                </b>
            </a>
        </b>
    </a>
}

let $a-elements := $algae//a

let $count-a-elements-at-level := function ($level) {
    $a-elements[count(./ancestor::element()) = $level] => count()
}

return for-each(0 to 4, $count-a-elements-at-level)
