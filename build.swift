#!/usr/bin/swift
import Foundation

let header = """
#!/usr/bin/swift

/// MASSE
/// Most Awful Static Site Engine
/// 
/// This is a single-file pure-swift static site engine
/// specifically built for the `Contravariance` podcast.
/// It was built on two train rides and offers a lot of
/// opportunities for improvements.


"""

let distTarget = "dist/masse.swift"
let sourceTarget = "Sources/Masse/"
let runCommand = "Masse.run()"

/// Generation

do {
  var output = header
  let files = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: sourceTarget), includingPropertiesForKeys: nil, options: [])
  for fileURL in files {
      print(try String(contentsOf: fileURL), terminator: "\n", to: &output)
  }
  output.append("\n\(runCommand)")
  try output.write(to: URL(fileURLWithPath: distTarget), atomically: true, encoding: .utf8)
} catch let error {
  print("Could not build \(distTarget)")
  print("Error: \(error)")
}

