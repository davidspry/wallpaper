//
//  DisplayTimer.swift
//  Wallpaper
//
//  Created by David Spry on 18/4/22.
//
//  Based on DisplayLink by Jose Canepa:
//  https://gist.github.com/CanTheAlmighty/ee76fbf701a61651fe439fcd6d25f41d
//

import AppKit

class DisplayTimer {
    let timer: CVDisplayLink
    let source: DispatchSourceUserDataAdd
    var callback: Optional<() -> ()> = nil
    var isRunning: Bool {
        return CVDisplayLinkIsRunning(timer)
    }

    /// Creates a new DisplayLink that gets executed on the given queue
    /// - Parameter queue: Queue which will receive the callback calls

    init?(onQueue queue: DispatchQueue = DispatchQueue.main) {
        source = DispatchSource.makeUserDataAddSource(queue: queue)

        var timerReference: CVDisplayLink? = nil
        var displayLinkStatus = CVDisplayLinkCreateWithActiveCGDisplays(&timerReference)

        if let timer = timerReference {
            displayLinkStatus = CVDisplayLinkSetOutputCallback(timer, {
                (timer: CVDisplayLink, currentTime: UnsafePointer<CVTimeStamp>, outputTime: UnsafePointer<CVTimeStamp>, _: CVOptionFlags, _: UnsafeMutablePointer<CVOptionFlags>, sourceUnsafeRaw: UnsafeMutableRawPointer?) -> CVReturn in

                if let sourceUnsafeRaw = sourceUnsafeRaw {
                    let sourceUnmanaged = Unmanaged<DispatchSourceUserDataAdd>.fromOpaque(sourceUnsafeRaw)
                    sourceUnmanaged.takeUnretainedValue().add(data: 1)
                }

                return kCVReturnSuccess
            }, Unmanaged.passUnretained(source).toOpaque())

            guard displayLinkStatus == kCVReturnSuccess else {
                print("A timer could not be created for the active display.")
                return nil
            }

            displayLinkStatus = CVDisplayLinkSetCurrentCGDisplay(timer, CGMainDisplayID())

            guard displayLinkStatus == kCVReturnSuccess else {
                print("The main display could not be set as the DisplayTimer's current display.")
                return nil
            }

            self.timer = timer
        } else {
            print("A timer could not be created for the active display.")
            return nil
        }

        source.setEventHandler { [weak self] in
            self?.callback?()
        }
    }

    deinit {
        if isRunning {
            stop()
        }
    }

    /// Start or resume the timer.

    func start() {
        guard !isRunning else {
            return
        }

        CVDisplayLinkStart(timer)
        
        source.resume()
    }

    /// Stop the timer.

    func stop() {
        guard isRunning else {
            return
        }

        CVDisplayLinkStop(timer)

        source.suspend()
    }
}
