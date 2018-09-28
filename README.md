# Masse

## Most Awful Static Site Engine

This is a single-file pure-swift static site engine
specifically built for the `Contravariance` podcast.
It was built on two train rides and offers a lot of
opportunities for improvements.

# Structure

The individual source files are (obviously) located
in the `Sources/Masse` folder. 

# Editing

You can generate an xcode project via:

```bash
$ swift package generate-xcodeproj
```

# Building

The root contains the `build.swift` script that takes
all the sources in `Sources/Masse` and concanates them into
`dist/masse.swift`. This, then is the distributable single-file
static site engine.

