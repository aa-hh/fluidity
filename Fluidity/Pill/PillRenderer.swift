import AppKit
import Metal
import MetalKit
import os

/// Draws the rim into an `MTKView`. The view's own display link drives the
/// frames; the controller pauses it while the pill is hidden, so a hidden pill
/// costs nothing.
@MainActor
final class PillRenderer: NSObject, MTKViewDelegate {
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    /// Called once per frame, before drawing, for that frame's uniforms.
    var frame: (() -> [Float])?
    private var hasLoggedMissingDrawable = false
    private static let log = Logger(subsystem: "com.fluidity.app", category: "Pill")

    /// Nil when this Mac cannot run the shader; the pill then stays hidden.
    init?(device: MTLDevice, pixelFormat: MTLPixelFormat) {
        guard let queue = device.makeCommandQueue() else {
            Self.log.error("Recording pill could not make a Metal command queue")
            return nil
        }
        do {
            let library = try device.makeLibrary(source: PillShader.source, options: nil)
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = library.makeFunction(name: PillShader.vertexFunction)
            descriptor.fragmentFunction = library.makeFunction(name: PillShader.fragmentFunction)
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            self.pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            Self.log.error("Recording pill shader failed to build: \(error.localizedDescription, privacy: .public)")
            return nil
        }
        self.queue = queue
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let size = view.bounds.size
        guard let uniforms = self.frame?() else { return }
        guard let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let buffer = self.queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: pass)
        else {
            if !self.hasLoggedMissingDrawable {
                self.hasLoggedMissingDrawable = true
                Self.log.error("Recording pill has no drawable to draw into (view \(view.bounds.size.debugDescription, privacy: .public))")
            }
            return
        }
        var viewSize = SIMD2<Float>(Float(size.width), Float(size.height))
        encoder.setRenderPipelineState(self.pipeline)
        uniforms.withUnsafeBytes { bytes in
            guard let base = bytes.baseAddress else { return }
            encoder.setFragmentBytes(base, length: bytes.count, index: 0)
        }
        encoder.setFragmentBytes(&viewSize, length: MemoryLayout<SIMD2<Float>>.stride, index: 1)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }
}
