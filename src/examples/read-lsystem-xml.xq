xquery version "3.1";

import module namespace linsy-read = "//line-o.de/ns/linsy/read" at "content/read.xqm";

declare option exist:serialize "method=html5 media-type=text/html";

declare variable $systems := collection("/db/apps/linsy/systems")//system;

(:
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:version "5";
declare option output:mime-type "text/html";
:)

<html>
    <head>
        <style><![CDATA[
            body { margin: 3em; }
            article { margin-block: 2em; border-block-end: thin solid black; display: grid; grid-template-columns: 1fr 1fr; }
            svg { max-height: 20em; }
            code { width: 100%; }
            .line { stroke: rgb(90,40,50);  stroke-width: 4; }
        ]]></style>
    </head>
    <body>
        <h1>Read System-Declarations</h1>
        {
        for $system in $systems
        return
            <article>
                <section>
                    <h2>System</h2>
                    <code><pre>
                    {
                        serialize(
                            $system,
                            map{"method": "xml", "indent": true()})
                    }
                    </pre></code>
                </section>

                <section>
                    <h2>Result</h2>
                    { linsy-read:system($system) }
                </section>
            </article>
        }
    </body>
</html>
