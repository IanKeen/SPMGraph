# SPMGraph
Basic little script for traversing a Swift PM graph to help resolve dependency issues

Just something I whipped up quickly to help diagnose problems, it's far from pretty but it (mostly) works :P

### Why?
Currently you can see a (much nicer) representation of the dependency graph with the command:
```
swift build --show-dependencies=text
```
The catch? if you have any dependency mismatches it will fail :(


### Usage
```
SPMGraph https://github.com/IanKeen/Chameleon
```
