### Multiple choices

Creating a multiple choice option for the template type is a bit more involved. We have to use `choice` for the type and define all the options that the user can select. 

    <parameter name='TemplateType' 
               type='choice' 
               default='3' 
               store='text' 
               prompt='Select the template type'>
      <choice label='&amp;Single templateFile'
              help="Creates a template that ocntains a single templateFile"
              value="Single"/>
      <choice label='Import from &amp;Directory'
              help="Creates a template that will deploy a directory full of files"
              value="Directory"/>
      <choice label='&amp;Empty'
              help="Create an empty template with a manifest"
              value="Empty"/>
    </parameter>

This gives our user the option to select any of those choices.

    Select the template type
    [S] Single templateFile  
    [D] Import from Directory  
    [E] Empty  
    [?] Help (default is "E"):

I am not sure if you noticed but I created those shortcut values of `S`,`D` and `E` by placing an `&amp;` into the `label` before the character that should be the shortcut for that option. This would be a  `&` except I needed to encode it as `&amp;` because we are working in XML.

### Dependant parameters

We need to present different parameters based on the selection to the previous choice. 