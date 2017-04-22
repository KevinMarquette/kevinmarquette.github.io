examples

https://github.com/PoshCode/Configuration/tree/master/Specs


I need to explain wildcards in steps, parameterized examples, the way before/after works better, and why g-w-t makes you write better tests

It's worth pointing out there's a Find-GherkinStep you can use to figure out which step definition will match step text ;-)

Some <examples> in my Configuration module.
https://github.com/PoshCode/Configuration/blob/master/Specs/LocalStoragePath.feature#L40-L49 … 
It's also regex! E.g. line 43 matches here:

Gherkin has Before/After each Feature/Scenario in steps
They apply across a whole test run
Pester Before/After apply to "IT" within context

