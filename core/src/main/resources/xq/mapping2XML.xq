xquery version "3.1" encoding "UTF-8";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";
declare namespace array = "http://www.w3.org/2005/xpath-functions/array";
declare namespace mapping = "http://docs.rackspace.com/identity/api/ext/MappingRules";
declare namespace xs = "http://www.w3.org/2001/XMLSchema";

declare default element namespace "http://docs.rackspace.com/identity/api/ext/MappingRules";

declare option output:method "xml";
declare option output:indent "yes";

(: declare variable $__JSON__ external; :)
declare variable $__JSON__ := "{&#34;rules&#34;:[{&#34;local&#34;:{&#34;user&#34;:{&#34;domain&#34;:&#34;{D}&#34;,&#34;name&#34;:&#34;{D}&#34;,&#34;email&#34;:&#34;{D(name)}@rackspace.com&#34;,&#34;roles&#34;:&#34;{D}&#34;,&#34;expire&#34;:&#34;{D}&#34;}}}],&#34;namespaces&#34;:{&#34;foo&#34;:&#34;bar&#34;}}";
declare variable $policyJSON := parse-json($__JSON__);


declare function mapping:convertValue($in as xs:string) as xs:string {
  replace($in,' ','&#xA0;')
};


declare function mapping:attributeFromValue ($attName as xs:string, $value as item()) as attribute()* {
  typeswitch ($value)
    case $s as xs:string return attribute {$attName} {mapping:convertValue($s)}
    case $b as xs:boolean return attribute {$attName} {mapping:convertValue(string($b))}
    case $a as array(*) return attribute {$attName} {string-join(for $i in $a?* return mapping:convertValue($i),' ')}
    case $o as map(*) return for $att in map:keys($o) return mapping:attributeFromValue($att, $o?($att))
    default return ()
};

declare function mapping:convertLocalAttribute($attribName as xs:string, $attribValue as item()) as element() {
  element {$attribName} {
    mapping:attributeFromValue("value",$attribValue)
  }
};

<rules xmlns="http://docs.rackspace.com/identity/api/ext/MappingRules"
       xmlns:xs="http://www.w3.org/2001/XMLSchema"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
       {
       if (map:contains($policyJSON,"namespaces")) then
         let $namespaces := $policyJSON?namespaces
         for $key in map:keys($namespaces) return namespace {$key} {$namespaces?($key)}
       else ()
       }

       {
         for $rule in $policyJSON?rules?* return
         <rule>
             <local>
                 {
                   let $local := $rule?local
                   for $localGroupName in map:keys($local) return element {$localGroupName} {
                     let $localGroup := $local?($localGroupName)
                     for $attributeName in map:keys($localGroup) return mapping:convertLocalAttribute($attributeName, $localGroup?($attributeName))
                   }
                 }
             </local>
         </rule>
       }
</rules>
