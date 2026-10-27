//
//  BackgroundDownloaderPlugin.swift
//  background_downloader
//
//  Created by Bram on 1/9/25.
//

import Flutter
import UIKit

@objc(BackgroundDownloaderPlugin) // Keep the Objective-C name for compatibility
public class BackgroundDownloaderPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    BDPlugin.register(with: registrar)
  }
}
