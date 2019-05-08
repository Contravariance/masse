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

## Generating show notes

The following format is expected in your `.bacf` file:

```
# title
- description1: url1
- description2: url2

- description3: url3

# anotherTitle
- description4: url4
```

This will generate:

```html
<div>
  <p>
  <h3>title</h3>
  <ul>
    <li><a href="url1">description1</a></li>
    <li><a href="url2">description2</a></li>
  </ul>
  <ul>
    <li><a href="url3">description3</a></li>
  </ul>
  </p>
  <p>
  <h3>anotherTitle</h3>
  <ul>
    <li><a href="url4">description4</a></li>
  </ul>
  </p>
<div>
```

# Building

The root contains the `build.swift` script that takes
all the sources in `Sources/Masse` and concanates them into
`dist/masse.swift`. This, then is the distributable single-file
static site engine.

