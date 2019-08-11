

# Bitwise operators

Bitwise operators perform calculations on the bits within the values and produce a new value as the result. Teaching bitwise operators is beyond the scope of this article, but I will highlight the operators. Hopefully, you will have your usecase already and just need these examples for the syntax.

* `-band` binary AND
* `-bor` binary OR
* `-nand` binary NOT AND
* `-xor` binary NOT OR

## -band binary and

A binary `AND` operation compares each bit between each value and if they both have a bit set, then the resulting value will have a bit set at that same location. Take a look at these two values in binary notation.

``` posh
PS> $lhs = 0x0110
PS> $rhs = 0x0101
PS> $lhs -band $rhs
0x0100
```

There is only one bit that these both have in common and you can see that the result has only that bit set. This value will evaluate to `$true` in an `if` statement because it is not all zeros. If none of the bits matched, then it would be `$false`.

## -bor binary or

The binary `OR` operator will compare each bit between values and if either bit is set, then the resulting value will have a bit set in that location. Using the same values as before:

``` posh
PS> $lhs = 0x0110
PS> $rhs = 0x0101
```

The `$lhs` has 2 bits set so both of those will be set in the result. Then the `$rhs` also has 2 bits set that will be set in the result. We will end up with 3 bits set. They do have one bit in common, but that does not impact the results for this operator.


``` posh
$ans = 0x0111
```

The binary `OR` is generally used to ensure that a bit gets flipped on.

## -nand binary not and

The binary `NAND` operator compares the bits that are not set between two values. The result of two bits that are not set is a set bit in the output. Take a close look at these examples.


``` posh
$lhs = 0x0110
$rhs = 0x0101
```


# binary not


todo: 0x0ABC is hex notation and not binary
