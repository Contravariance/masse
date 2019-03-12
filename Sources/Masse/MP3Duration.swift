/// Read MP3 files and parse the headers in order to calculate the duration of the
/// MP3 file.
/// Supports constant bitrate and variable bitrate
/// Links:
/// - [Format reference](https://www.codeproject.com/Articles/8295/MPEG-Audio-Frame-Header)
/// - [Audio test file source](http://freemusicarchive.org/music/Karine_Gilanyan/Beethovens_Sonata_No_15_in_D_Major/Beethoven_-_Piano_Sonata_nr15_in_D_major_op28_Pastoral_-_I_Allegro)
/// - [Non-audio test file source](https://www.pexels.com/photo/close-up-of-tiled-floor-258805/)


/// Errors that can happen during reading the input stream
enum InputStreamError: Error {
    case endOfBuffer
    case streamError(Error?)
}

extension InputStream {
    /// Read `length` into a buffer. Throw an `InputStreamError` on failure
    func readInto(buffer: UnsafeMutablePointer<UInt8>, length: Int) throws {
        switch self.read(buffer, maxLength: length) {
        case 0: throw InputStreamError.endOfBuffer
        case -1: throw InputStreamError.streamError(self.streamError)
        default: ()
        }
    }
}

/// Various errors that can happen during MP3 decoding
/// Especially for invalid MP3 files
enum MP3DurationError: Error {
    case streamNotOpen
    case invalidFile(URL)
    case forbiddenVersion(UInt32)
    case forbiddenLayer
    case forbiddenMode
    case invalidBitrate(Int)
    case invalidSamplingRate(Int)
    case unexpectedFrame(Int)
    case readError(Error)
}

/// Lightweight wrapper around the seconds and nanoseconds
/// that are encoded in an MP3 file
public struct Duration {
    public private(set) var seconds: Double
    
    public var minutes: Double {
        return seconds / 60.0
    }
    
    init() {
        seconds = 0
    }
    
    init(seconds: UInt64, nanoseconds: UInt64) {
        self.seconds = Double(seconds)
        self.add(nanoseconds: nanoseconds)
    }
    
    mutating func add(seconds: UInt64) {
        self.seconds += Double(seconds)
    }
    
    mutating func add(nanoseconds: UInt64) {
        let nanosPerSec = 1_000_000_000
        self.seconds += Double(nanoseconds) / Double(nanosPerSec)
    }
}

extension Duration: CustomStringConvertible {
    public var description: String {
        // NSDateComponentsFormatter could also be used
        let minutes: Double = seconds / 60.0
        let remainingSeconds = seconds.truncatingRemainder(dividingBy: 60.0)
        let hours: Double = minutes / 60.0
        let remainingMinutes = minutes.truncatingRemainder(dividingBy: 60.0)
        return String(format: "%02d:%02d:%02d", Int(hours), Int(remainingMinutes), Int(remainingSeconds))
    }
}

/// Calculate the duration of an MP3 file
/// Can be initialized with a `URL` or a `NSInputStream`. Note that the inputStream has to be opened!
/// https://www.mp3-tech.org/programmer/frame_header.html
public struct MP3DurationCalculator {
    
    private let inputStream: InputStream
    
    /// Constants
    /// Various constants for MP3 Decoding
    
    private enum Version: Int {
        case mpeg1, mpeg2, mpeg25
        
        static func fromHeader(_ header: UInt32) throws -> Version {
            // Shift by 19 to reach the two bits at position 19, 20
            // then and with 0b11000000 so that only position 19/20 stay
            // and then convert them (00, 01, 10, 11) to a number
            // its is the same for the code below
            let number = (header >> 19) & 0b11

            switch number {
            case 0: return .mpeg25
            case 2: return .mpeg2
            case 3: return .mpeg1
            default: throw MP3DurationError.forbiddenVersion(number)
            }
        }
    }
    
    private enum Layer: Int {
        case notDefined, layer1, layer2, layer3
        
        static func fromHeader(_ header: UInt32) throws -> Layer {
            let number = (header >> 17) & 0b11
            switch number {
            case 0: return .notDefined
            case 1: return .layer3
            case 2: return .layer2
            case 3: return .layer1
            default: throw MP3DurationError.forbiddenLayer
            }
        }
    }
    
    private enum Mode: Int {
        case stereo, jointStereo, dualChannel, mono
        
        static func fromHeader(_ header: UInt32) throws -> Mode {
            let number = (header >> 6) & 0b11
            switch number {
            case 0: return .stereo
            case 1: return .jointStereo
            case 2: return .dualChannel
            case 3: return .mono
            default: throw MP3DurationError.forbiddenMode
            }
        }
    }
    
    private let bitRates = [
        [
            Array(repeating: 0, count: 16),
            // Mpeg1 Layer1
            [0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0],
            // Mpeg1 Layer2
            [0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0],
            // Mpeg1 Layer3
            [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0],
            ],
        [
            Array(repeating: 0, count: 16),
            // Mpeg2 Layer1
            [0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0],
            // Mpeg2 Layer2
            [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0],
            // Mpeg2 Layer3
            [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0],
            ],
        [
            Array(repeating: 0, count: 16),
            // Mpeg25 Layer1
            [0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0],
            // Mpeg25 Layer2
            [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0],
            // Mpeg25 Layer3
            [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0],
            ],
        ]
    
    private let samplingRates = [
        [44100, 48000, 32000, 0], // Mpeg1
        [22050, 24000, 16000, 0], // Mpeg2
        [11025, 12000, 8000, 0], // Mpeg25
    ]
    
    private let samplesPerFrame = [
        [0, 384, 1152, 1152], // Mpeg1
        [0, 384, 1152, 576],  // Mpeg2
        [0, 384, 1152, 576], // Mpeg25
    ]
    
    private let sideInformationSizes = [
        [32, 32, 32, 17], // Mpeg1
        [17, 17, 17, 9],  // Mpeg2
        [17, 17, 17, 9], // Mpeg25
    ]
    
    private func calculateBitrate(for version: Version, layer: Layer, encodedBitrate: Int) throws -> Int {
        guard encodedBitrate < 15 else {
            throw MP3DurationError.invalidBitrate(encodedBitrate)
        }
        guard layer != .notDefined else {
            throw MP3DurationError.forbiddenLayer
        }
        return 1000 * bitRates[version.rawValue][layer.rawValue][encodedBitrate]
    }
    
    private func calculateSamplingRate(for version: Version, encodedSamplingRate: Int) throws -> Int {
        guard encodedSamplingRate < 3 else {
            throw MP3DurationError.invalidSamplingRate(encodedSamplingRate)
        }
        return samplingRates[version.rawValue][encodedSamplingRate]
    }
    
    private func calculateSamplesPerFrame(for version: Version, layer: Layer) throws -> Int {
        guard layer != .notDefined else {
            throw MP3DurationError.forbiddenLayer
        }
        return samplesPerFrame[version.rawValue][layer.rawValue]
    }
    
    private func calculateSideInformationSize(for version: Version, mode: Mode) throws -> Int {
        return sideInformationSizes[version.rawValue][mode.rawValue]
    }
    
    /// Lightweight wrapper around a `UnsafeMutablePointer` in order to read unneeded
    /// data from a inputStream into something. This will resize the buffer according
    /// to the size requirements.
    private struct Dump {
        private var buffer: UnsafeMutablePointer<UInt8>
        private var size = 16 * 1024
        
        init() {
            self.buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: self.size)
        }
        
        mutating func skip(reader: InputStream, length: Int) throws {
            if length > size {
                buffer.deallocate()
                buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
                self.size = length
            }
            try reader.readInto(buffer: self.buffer, length: length)
        }
    }
    
    /// Initialize the Calculator with a `URL` to an mp3 file
    public init(url: URL) throws {
        guard let inputStream = InputStream(url: url) else {
            throw MP3DurationError.invalidFile(url)
        }
        inputStream.open()
        try self.init(inputStream: inputStream)
    }
    
    /// Initialize the Calculator with an `openend` `NSInputStream`. This is particularly
    /// useful as `NSInputStream`s can also be contructed from `NSData`
    /// throws if the stream is not open
    public init(inputStream: InputStream) throws {
        guard inputStream.streamStatus == .open else {
            throw MP3DurationError.streamNotOpen
        }
        self.inputStream = inputStream
    }
    
    /// Calculate the duration of an MP3 file by parsing headers
    public func calculateDuration() throws -> Duration {
        defer {
            inputStream.close()
        }
        let headerBufferLength = 4
        let headerBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerBufferLength)
        headerBuffer.initialize(repeating: 0, count: headerBufferLength)
        
        var dump = Dump()
        
        var duration = Duration()
        while true {
            do {
                try inputStream.readInto(buffer: headerBuffer, length: headerBufferLength)
            } catch InputStreamError.endOfBuffer {
                break
            } catch let error {
                throw MP3DurationError.readError(error)
            }
            let header = (UInt32(headerBuffer.pointee)) << 24
                | (UInt32(headerBuffer.advanced(by: 1).pointee)) << 16
                | (UInt32(headerBuffer.advanced(by: 2).pointee)) << 8
                | (UInt32(headerBuffer.advanced(by: 3).pointee))
            
            let isMP3 = (header >> 21) == 0x7ff
            if isMP3 {
                let version = try Version.fromHeader(header)
                let layer = try Layer.fromHeader(header)
                let mode = try Mode.fromHeader(header)
                let encodedBitrate = (header >> 12) & 0b1111
                let encodedSamplingRate = (header >> 10) & 0b11
                let padding = ((header >> 9) & 1) != 0 ? 1 : 0
                let samplingRate = try calculateSamplingRate(for: version, encodedSamplingRate: Int(encodedSamplingRate))
                let numSamples = try calculateSamplesPerFrame(for: version, layer: layer)
                let xingOffset = try calculateSideInformationSize(for: version, mode: mode)
                
                let xingBufferLength = 12
                let xingBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: xingBufferLength)
                xingBuffer.initialize(repeating: 0, count: xingBufferLength)
                
                try dump.skip(reader: inputStream, length: xingOffset)
                
                try inputStream.readInto(buffer: xingBuffer, length: xingBufferLength)
                let tag = String(bytesNoCopy: xingBuffer, length: 4, encoding: .ascii, freeWhenDone: false)
                
                let billion: UInt64 = 1_000_000_000
                
                if tag == "Xing" || tag == "Info" {
                    let hasFrames = (xingBuffer.advanced(by: 7).pointee & 1) != 0
                    if hasFrames {
                        let numFrames = (UInt32(xingBuffer.advanced(by: 8).pointee)) << 24
                            | (UInt32(xingBuffer.advanced(by: 9).pointee)) << 16
                            | (UInt32(xingBuffer.advanced(by: 10).pointee)) << 8
                            | (UInt32(xingBuffer.advanced(by: 11).pointee))
                        let rate = UInt64(samplingRate)
                        let framesBySamples = UInt64(numFrames) * UInt64(numSamples)
                        let seconds = framesBySamples / rate
                        let nanoseconds = (billion * framesBySamples) / rate - billion * seconds
                        return Duration(seconds: seconds, nanoseconds: nanoseconds)
                    }
                }
                
                let bitrate = try calculateBitrate(for: version, layer: layer, encodedBitrate: Int(encodedBitrate))
                let frameLength = (numSamples / 8 * bitrate / samplingRate + padding)
                
                try dump.skip(reader: inputStream, length: frameLength - headerBufferLength - xingOffset - xingBufferLength)
                
                let frameDuration = (UInt64(numSamples) * billion) / UInt64(samplingRate)
                duration.add(nanoseconds: frameDuration)
                continue
            }
            
            // ID3v2 frame
            let isID3v2 = "ID3" == String(bytesNoCopy: headerBuffer, length: 3, encoding: .ascii, freeWhenDone: false)
            if isID3v2 {
                let id3v2Length = 6
                let id3v2Buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: id3v2Length)
                id3v2Buffer.initialize(repeating: 0, count: id3v2Length)
                try inputStream.readInto(buffer: id3v2Buffer, length: id3v2Length)
                let flags = id3v2Buffer.advanced(by: 1).pointee
                let footerSize = (flags & 0b0001_0000) != 0 ? 10 : 0
                let tagSize = Int(UInt32(id3v2Buffer.advanced(by: 5).pointee)
                    | (UInt32(id3v2Buffer.advanced(by: 4).pointee) << 7)
                    | (UInt32(id3v2Buffer.advanced(by: 3).pointee) << 14)
                    | (UInt32(id3v2Buffer.advanced(by: 2).pointee) << 21))
                
                
                try dump.skip(reader: inputStream, length: tagSize + footerSize)
                continue
            }
            
            // ID3v1 frame
            let isID3v1 = "TAG" == String(bytesNoCopy: headerBuffer, length: 3, encoding: .ascii, freeWhenDone: false)
            if isID3v1 {
                try dump.skip(reader: inputStream, length: 128 - headerBufferLength)
                continue
            }
            
            throw MP3DurationError.unexpectedFrame(Int(header))
        }
        
        return duration
    }
}
