@preconcurrency import AVFoundation
import AudioToolbox
import CoreAudio
import FluidAudio
import Foundation
import os

private let log = Logger(subsystem: "com.fluidity.app", category: "audio")

/// The real microphone: Core Audio's input unit (AUHAL) on the chosen input device, converted to 16 kHz mono
/// with FluidAudio's `AudioConverter`.
///
/// The unit is built and initialised ahead of time, at launch and whenever the default input device changes, but
/// started only for a recording. So the microphone is in use only while recording, and a key press costs one start
/// call plus the hardware's own delay to the first audio. A changed choice rebuilds the unit on the next start.
public final class CoreAudioInput: AudioInput, @unchecked Sendable {
    public enum Failure: Error { case noInputDevice, coreAudio(OSStatus) }

    /// One `start()` until `stop()` or a lost device.
    private final class Session: @unchecked Sendable {
        let handler: @Sendable (AudioInputEvent) -> Void
        let device: String
        let startedAt = ContinuousClock.now
        /// Touched only on `queue`.
        var heardAudio = false
        var conversionFailures = 0

        init(handler: @escaping @Sendable (AudioInputEvent) -> Void, device: String) {
            self.handler = handler
            self.device = device
        }
    }

    /// Serialises building, starting, stopping and dropping the unit. The I/O thread never takes it,
    /// because stopping a unit waits for an I/O callback in progress.
    private let unitLock = NSLock()
    private var unit: InputUnit?
    private var aliveListener: (device: AudioDeviceID, block: AudioObjectPropertyListenerBlock)?
    /// Taken on the I/O thread, so held only to read or swap the session.
    private let lock = NSLock()
    private var session: Session?
    /// Converts and delivers audio in order, and handles device changes, off the I/O thread.
    private let queue = DispatchQueue(label: "com.fluidity.audio-input")
    private let converter = AudioConverter()
    /// The device to record from, or `nil` for the macOS default. Read on every start, so keep it cheap.
    private let chosenDevice: @Sendable () -> AudioDeviceID?

    public init(device: @escaping @Sendable () -> AudioDeviceID?) {
        chosenDevice = device
        // razor: the listener lives as long as the app, so it is never removed.
        var address = propertyAddress(kAudioHardwarePropertyDefaultInputDevice)
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, queue) { [weak self] _, _ in
            guard let self else { return }
            // A new default leaves a chosen microphone, or Automatic's built-in one, recording as it was.
            guard unitLock.withLock({ unit?.isCurrent(for: chosenDevice() ?? defaultInputDevice()) != true }) else { return }
            inputChanged("default input device changed")
        }
        queue.async { [weak self] in
            guard let self else { return }
            unitLock.withLock { rebuild() }
        }
    }

    public func start(_ handler: @escaping @Sendable (AudioInputEvent) -> Void) throws {
        try unitLock.withLock {
            if unit?.isCurrent(for: chosenDevice() ?? defaultInputDevice()) != true { rebuild() }
            guard let built = unit else { throw Failure.noInputDevice }
            let session = Session(handler: handler, device: built.name)
            lock.withLock { self.session = session }
            var status = AudioOutputUnitStart(built.audioUnit)
            if status != noErr {
                log.error("input start on \(built.name, privacy: .public) failed (\(status, privacy: .public)); rebuilding")
                rebuild()
                status = unit.map { AudioOutputUnitStart($0.audioUnit) } ?? status
            }
            guard status == noErr else {
                lock.withLock { self.session = nil }
                throw Failure.coreAudio(status)
            }
            let took = (ContinuousClock.now - session.startedAt) / .milliseconds(1)
            log.notice("input start: \(session.device, privacy: .public), start call took \(took, format: .fixed(precision: 1), privacy: .public) ms")
        }
    }

    public func stop() {
        lock.withLock { session = nil }
        unitLock.withLock {
            guard let unit else { return }
            AudioOutputUnitStop(unit.audioUnit)
            AudioUnitReset(unit.audioUnit, kAudioUnitScope_Global, 0)
        }
        // Lets audio already queued see the cleared session, so no handler call follows this return.
        queue.sync {}
        log.notice("input stop")
    }

    /// On the I/O thread.
    private func received(_ buffer: AVAudioPCMBuffer) {
        guard let session = lock.withLock({ self.session }) else { return }
        nonisolated(unsafe) let buffer = buffer
        queue.async { [self] in
            guard lock.withLock({ self.session === session }) else { return }
            if !session.heardAudio {
                session.heardAudio = true
                let wait = (ContinuousClock.now - session.startedAt) / .milliseconds(1)
                log.notice("input first audio: \(wait, format: .fixed(precision: 1), privacy: .public) ms after start, \(session.device, privacy: .public)")
            }
            do {
                let samples = try converter.resampleBuffer(buffer)
                if !samples.isEmpty { session.handler(.samples(samples)) }
            } catch {
                session.conversionFailures += 1
                if session.conversionFailures <= 3 {
                    log.error("input: resample failed: \(String(describing: error), privacy: .public)")
                }
            }
        }
    }

    /// On `queue`. Rebuilds the unit for the current default device and ends a recording in progress.
    private func inputChanged(_ reason: String) {
        let lost = lock.withLock {
            defer { session = nil }
            return session
        }
        unitLock.withLock { rebuild() }
        guard let lost else { return }
        log.error("\(reason, privacy: .public) while recording; input lost")
        lost.handler(.lost)
    }

    /// Drops the unit and builds a stopped one for the chosen device, falling back to the macOS default.
    /// Call with `unitLock` held.
    private func rebuild() {
        unit?.dispose()
        unit = nil
        if let (device, block) = aliveListener {
            var address = propertyAddress(kAudioDevicePropertyDeviceIsAlive)
            AudioObjectRemovePropertyListenerBlock(device, &address, queue, block)
            aliveListener = nil
        }
        let fallback = defaultInputDevice()
        guard let device = chosenDevice() ?? fallback else {
            log.error("input: no default input device")
            return
        }
        build(device)
        if unit == nil, let fallback, fallback != device {
            // The chosen device vanished between choosing it and building the unit.
            log.error("input: using the macOS default instead")
            build(fallback)
        }
    }

    /// Call with `unitLock` held.
    private func build(_ device: AudioDeviceID) {
        do {
            let built = try InputUnit.make(device: device) { [weak self] in
                self?.received($0)
            } onFailure: { [weak self] status in
                // A format change mid-recording makes every render fail, so the recording ends as lost.
                guard let self else { return }
                queue.async { self.inputChanged("audio render failed (\(status))") }
            }
            unit = built
            let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in self?.inputChanged("input device went away") }
            var address = propertyAddress(kAudioDevicePropertyDeviceIsAlive)
            AudioObjectAddPropertyListenerBlock(device, &address, queue, block)
            aliveListener = (device, block)
            log.notice("input ready: \(built.name, privacy: .public), \(built.format.sampleRate, privacy: .public) Hz, \(built.format.channelCount, privacy: .public) ch")
        } catch {
            log.error("input: building the unit failed: \(String(describing: error), privacy: .public)")
        }
    }
}

/// A built and initialised AUHAL for one input device, stopped until `AudioOutputUnitStart`.
private final class InputUnit: @unchecked Sendable {
    let audioUnit: AudioUnit
    let device: AudioDeviceID
    let name: String
    /// Float32, non-interleaved, at the device's own rate and channel count: AUHAL does not resample input.
    let format: AVAudioFormat
    /// Filled on the I/O thread; each render is copied out before `onBuffer`.
    private let buffer: AVAudioPCMBuffer
    private let onBuffer: (AVAudioPCMBuffer) -> Void
    /// Called on the I/O thread on the first failed render only.
    private let onFailure: (OSStatus) -> Void
    /// Touched only on the I/O thread.
    private var failed = false

    private init(audioUnit: AudioUnit, device: AudioDeviceID, format: AVAudioFormat, buffer: AVAudioPCMBuffer,
                 onBuffer: @escaping (AVAudioPCMBuffer) -> Void, onFailure: @escaping (OSStatus) -> Void) {
        self.audioUnit = audioUnit
        self.device = device
        self.name = deviceName(device)
        self.format = format
        self.buffer = buffer
        self.onBuffer = onBuffer
        self.onFailure = onFailure
    }

    static func make(device: AudioDeviceID, onBuffer: @escaping (AVAudioPCMBuffer) -> Void,
                     onFailure: @escaping (OSStatus) -> Void) throws -> InputUnit {
        var description = AudioComponentDescription(
            componentType: kAudioUnitType_Output, componentSubType: kAudioUnitSubType_HALOutput,
            componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
        guard let component = AudioComponentFindNext(nil, &description) else { throw CoreAudioInput.Failure.noInputDevice }
        var instance: AudioUnit?
        try check(AudioComponentInstanceNew(component, &instance))
        guard let audioUnit = instance else { throw CoreAudioInput.Failure.noInputDevice }
        do {
            try setProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, UInt32(1))
            try setProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, UInt32(0))
            try setProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, 0, device)
            let hardware = try getProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, AudioStreamBasicDescription())
            guard hardware.mSampleRate > 0, hardware.mChannelsPerFrame > 0 else { throw CoreAudioInput.Failure.noInputDevice }
            var client = AudioStreamBasicDescription(
                mSampleRate: hardware.mSampleRate, mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved,
                mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4,
                mChannelsPerFrame: hardware.mChannelsPerFrame, mBitsPerChannel: 32, mReserved: 0)
            try setProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, client)
            let maxFrames = try getProperty(audioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, UInt32(0))
            guard let format = AVAudioFormat(streamDescription: &client),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: max(maxFrames, 4096))
            else { throw CoreAudioInput.Failure.noInputDevice }
            let unit = InputUnit(audioUnit: audioUnit, device: device, format: format, buffer: buffer,
                                 onBuffer: onBuffer, onFailure: onFailure)
            let callback = AURenderCallbackStruct(inputProc: renderInput, inputProcRefCon: Unmanaged.passUnretained(unit).toOpaque())
            try setProperty(audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 0, callback)
            try check(AudioUnitInitialize(audioUnit))
            return unit
        } catch {
            AudioComponentInstanceDispose(audioUnit)
            throw error
        }
    }

    /// Whether the unit is still on `wanted` and its format, so it can start as built.
    func isCurrent(for wanted: AudioDeviceID?) -> Bool {
        guard wanted == device,
              let hardware = try? getProperty(audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, AudioStreamBasicDescription())
        else { return false }
        return hardware.mSampleRate == format.sampleRate && hardware.mChannelsPerFrame == format.channelCount
    }

    func dispose() {
        AudioOutputUnitStop(audioUnit)
        AudioUnitUninitialize(audioUnit)
        AudioComponentInstanceDispose(audioUnit)
    }

    /// On the I/O thread.
    func render(_ flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>, _ timeStamp: UnsafePointer<AudioTimeStamp>,
                _ bus: UInt32, _ frames: UInt32) -> OSStatus {
        guard frames <= buffer.frameCapacity else { return fail(kAudioUnitErr_TooManyFramesToProcess) }
        buffer.frameLength = frames
        let status = AudioUnitRender(audioUnit, flags, timeStamp, bus, frames, buffer.mutableAudioBufferList)
        guard status == noErr else { return fail(status) }
        guard let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let to = copy.floatChannelData else { return status }
        copy.frameLength = frames
        // Reads the buffer list, not `floatChannelData`, in case the render pointed it at the unit's own memory.
        for (channel, rendered) in UnsafeMutableAudioBufferListPointer(buffer.mutableAudioBufferList).enumerated()
        where channel < Int(format.channelCount) {
            guard let data = rendered.mData else { continue }
            to[channel].update(from: data.assumingMemoryBound(to: Float.self), count: Int(frames))
        }
        onBuffer(copy)
        return noErr
    }

    private func fail(_ status: OSStatus) -> OSStatus {
        if !failed {
            failed = true
            onFailure(status)
        }
        return status
    }
}

private let renderInput: AURenderCallback = { refCon, flags, timeStamp, bus, frames, _ in
    Unmanaged<InputUnit>.fromOpaque(refCon).takeUnretainedValue().render(flags, timeStamp, bus, frames)
}

private func check(_ status: OSStatus) throws {
    guard status == noErr else { throw CoreAudioInput.Failure.coreAudio(status) }
}

private func setProperty<T>(_ unit: AudioUnit, _ property: AudioUnitPropertyID, _ scope: AudioUnitScope,
                            _ element: AudioUnitElement, _ value: T) throws {
    try check(withUnsafePointer(to: value) {
        AudioUnitSetProperty(unit, property, scope, element, $0, UInt32(MemoryLayout<T>.size))
    })
}

private func getProperty<T>(_ unit: AudioUnit, _ property: AudioUnitPropertyID, _ scope: AudioUnitScope,
                            _ element: AudioUnitElement, _ initial: T) throws -> T {
    var value = initial
    var size = UInt32(MemoryLayout<T>.size)
    try check(withUnsafeMutablePointer(to: &value) { AudioUnitGetProperty(unit, property, scope, element, $0, &size) })
    return value
}

/// The device's name and how it connects (`bltn`, `usb `, `blue`), for the logs.
private func deviceName(_ device: AudioDeviceID) -> String {
    let code = withUnsafeBytes(of: transportType(device).bigEndian) { String(decoding: $0, as: UTF8.self) }
    return "\(stringProperty(device, kAudioObjectPropertyName) ?? "unknown") [\(code)]"
}
