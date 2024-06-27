# DOCS

## Run/Build

First, get the Odin compiler from [Odin website](https://odin-lang.org/).

Then, call

```
odin run src -out:shrubs.exe -collection:shrubs=src
```

If a debug build is needed for debugger, just add `-debug` option. The `-collection:shrubs=src` is needed to use the "engine" code nicely all around.

## Conventions

Here are listed some naming conventions. They are to some extent quite arbitrary, but using same convention throughout the project minimizes mental friction to understand what is happening.

For variable, constant, procedure, etc. naming, use Odin conventions, probably explained at [Odin website](https://odin-lang.org/).

For creating and destroying complex components, that require memory or other resource allocation and freeing, use words `create_XXX` and `destroy_XXX`. This is similar, but different enough from that of Odin `make/delete`, so it easy at glance to see where this comes from. Example: 

```
BigStuff :: struct { ... }

create_big_stuff :: proc(...) -> BigStuff { ... }
destroy_big_stuff :: proc(bs : ^BigStuff) { ... }
```
