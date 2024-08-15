# DOCS

## Run/Build

First, get the Odin compiler from [Odin website](https://odin-lang.org/).

Then, call

```
odin run src -out:shrubs.exe -collection:shrubs=src
```

If a debug build is needed for debugger, just add `-debug` option. The `-collection:shrubs=src` is needed to use the "engine" code nicely all around.

## Coding Conventions

Here are listed some naming conventions. They are to some extent quite arbitrary, but using same convention throughout the project minimizes mental friction to understand what is happening.

For variable, constant, procedure, etc. naming, use Odin conventions, probably explained at [Odin website](https://odin-lang.org/).

### Create/Destroy

For creating and destroying complex components, that require memory or other resource allocation and freeing, use words `create_XXX` and `destroy_XXX`. This is similar, but different enough from that of Odin `make/delete`, so it easy at glance to see where this comes from. Example: 

```
BigStuff :: struct { ... }

create_big_stuff :: proc(...) -> BigStuff { ... }
destroy_big_stuff :: proc(bs : ^BigStuff) { ... }
```

### Initialize/Terminate

For some singleton-like systems, which have a single static hidden instance, use `initialize` and `terminate`. Mostly these are engine sub-systems, such as
graphics and gui, and they don't have an assosiated object returned, although resources might privately be stored in a struct. Example

```
initialize :: proc (...) { /* create whatever necessary resources */ }
terminate :: proc() { /* free resource */ }
```

### Procedure naming

Some struct types represent some sort of entity in game. These will have some functions that are common across all entity types, such as update and render and some of them will have some functions like control or trigger. In the former case, name them with the common function name first, and in the latter put the type first. Example

```
Hoverbike :: struct { ... }

update_hoverbike :: proc(h : ^Hoverbike) { ... }
hoverbike_control :: proc(h : ^Hoverbike, ...) { ... }
```

Reasoning is that the first are typically used with similar procedures and successive lines will then align nicely to allow reader to quickly glance the types being e.g. updated:

```
update_hoverbike(...)
update_player_character(...)
update_vending_machine(...)
```

The second is typically used in an arbitrary context, so it is beneficial to be able to easily assess the type. Also this way there is quick way to tell apart "engine magic" procedures from the types' unique procedures.

### Indentation

Use tabs to indent. Every programmer has their own preference on how much to indent (correct answer is 4, btw) and using tab instead of multiple spaces allows everyone to set the tab width to whatever they want to in their text editor settings (if you cannot do this in you favourite editor, it is time for a new favourite editor).

### Commenting

(This paragraph should be re-written, its a quick and little vague) Avoid commenting in the end of the line. Sometimes, when it is a super short comment that adds a small nuance in understanding, this is acceptable. Other times, when comment is at all longer, jus put it on top of the line it refers to. This way, there is always (or at least most of the time) just one idea per line, and reading is less confusing. Also, typically comments act as sort of title or foreshadow to the line or section they refer to, so also from that point of view it is better to put comment first.

Prefix todo comments with `Todo(Name): `, like 

```
// Todo(Leo): this piece of crap needs to rewritten. I needed a quick solution, 
// but is is neither clear or efficient.
HACK_do_an_important_operation :: proc (seven_pointers : []rawptr) { ... }
```

## LOD System

As of now, LOD system primarily covers terrain and other scenery, as there pretty much is nothing else. Initially, all different systems use same granularity, but this likely need to be revisited later (probably quite soon).