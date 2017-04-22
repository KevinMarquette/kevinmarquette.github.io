
Adventures in coding.

I was in need of a good coding project and have been working with a lot of JSON in Powershell recently. I thought it would be fun to write a JSON to hastable parser. 

I know I could use `ConvertFrom-Json` to get a `PSCustomObject` and then recursively walk it to create my hashtable. I also know there are libraries out there like [Newtonsoft's Json.Net](* Then clean your code up. Whatever you do, be consistent. You can break a lot of the best practices and recommendations, just be consistent about it. ) to do this. But that takes all the fun out of it.

My first thought is to parse the file one character at a time. I think I will need a small state machine and to keep track of nested objects and arrays. 

