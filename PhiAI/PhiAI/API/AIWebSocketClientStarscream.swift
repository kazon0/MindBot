//
//  AIWebSocketClientStarscream.swift
//  PhiAI
//

import Foundation
import Starscream


class AIWebSocketClientStarscream: NSObject {
    private var socket: WebSocket?
    private var token: String?

    var onReceiveMessage: ((String) -> Void)?
    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onError: ((Error) -> Void)?
    
    func connect(token: String) {
        print("连接 WebSocket，使用 token: \(token)")
        self.token = token

        var request = URLRequest(url: URL(string: "ws://c364b48b.natappfree.cc/api/ai/chat/websocket")!)
        request.timeoutInterval = 30
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        socket = WebSocket(request: request)
        socket?.onEvent = { [weak self] event in
            self?.handle(event: event)
        }
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    func send(message: String, sessionId: Int64?, modelType: String) {
        var payload: [String: Any] = [
            "modelType": modelType,
            "message": message
        ]

        if let sessionId = sessionId {
            payload["sessionId"] = sessionId
        }

        if let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
           let jsonString = String(data: data, encoding: .utf8) {
            print("[WebSocket] 发送消息内容：\(jsonString)")
            socket?.write(string: jsonString) {
                print("[WebSocket] 消息发送完成")
            }
        } else {
            print("[WebSocket] 消息序列化失败")
        }
    }


    private func handle(event: WebSocketEvent) {
        switch event {
        case .connected(let headers):
            print(" WebSocket connected: \(headers)")
            onConnect?()
        case .disconnected(let reason, let code):
            print(" Disconnected: \(reason) (\(code))")
            onDisconnect?(nil)
        case .text(let string):
            print(" Message received: \(string)")
            onReceiveMessage?(string)
        case .error(let error):
            if let error = error {
                print(" WebSocket error: \(error)")
                onError?(error)
            }
        default:
            break
        }
    }
}
