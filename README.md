# csdoc

Take a boring, unhelpful C# xml documentation file and transform it into most robust xml documentation, and eventually HTML documentation, in the spirit of javadoc

## How to Use

Apply `transforms/csdoc.xsl` to your original C# documentation file, and save the result to a seperate xml file, and voila!

### bash

    xsltproc transforms/csdoc.xsl MyAssembly.xml > MyAssembly.csdoc.xml
