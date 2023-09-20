xquery version "3.1";

import module namespace linsy-read = "//line-o.de/ns/linsy/read" at "read.xqm";

(
    <system iterations="2" axiom="0">
        <grammar>
            <symbol match="1">11</symbol>
            <symbol match="0">1[0]0</symbol>
            <terminal match="[" />
            <terminal match="]" />
        </grammar>
    </system>
,
    <system iterations="2" axiom="0" seed="1">
        <grammar type="stochastic">
            <symbol match="1">11</symbol>
            <symbol match="0">
                <option probability="0.475">1[0]0</option>
                <option probability="0.475">11[0]0</option>
                <option probability="0.05">0</option>
            </symbol>
            <terminal match="[" />
            <terminal match="]" />
        </grammar>
    </system>
,
    <system iterations="2" axiom="0">
        <grammar type="stochastic">
            <symbol match="1">
                <option probability="0.85">11</option>
                <option probability="0.15">1</option>
            </symbol>
            <symbol match="0">
                <option probability="0.475">1[0]0</option>
                <option probability="0.475">11[0]0</option>
                <option probability="0.05">0</option>
            </symbol>
            <terminal match="[" />
            <terminal match="]" />
        </grammar>
    </system>
)
! linsy-read:system(.)
