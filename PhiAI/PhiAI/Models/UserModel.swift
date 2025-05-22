//
//  UserModel.swift
//  PhiAI
//

import Foundation

// 网络返回的用户数据结构
struct LoginResponse: Codable {
    let code: Int
    let message: String
    let data: LoginData?
}

struct LoginData: Codable {
    let permissions: [String]
    let roles: [String]
    let token: String
    let user: UserInfo
}

// MARK: - UserInfoResponse
struct UserInfoResponse: Codable {
    let code: Int
    let message: String
    let data: UserInfo?
}

// MARK: - UserInfo
struct UserInfo: Codable {
    var id: Int
    var username: String
    var password: String?
    var realName: String?
    var avatar: String?
    var phone: String?
    var email: String?
    var gender: Int?
    var status: Int?
    var createTime: String?
    var updateTime: String?
    var roles: [Role]?
    var permissions: [Permission]?
}

// MARK: - Role
struct Role: Codable {
    let id: Int
    let name: String
    let code: String
    let description: String?
    let status: Int
    let createTime: String
    let updateTime: String
    let permissions: [Permission]?
}

// MARK: - Permission
struct Permission: Codable {
    let id: Int
    let name: String
    let code: String
    let type: Int
    let status: Int
    let parentId: Int
    let sort: Int
    let icon: String?
    let component: String?
    let path: String?
    let createTime: String
    let updateTime: String
    let children: [Permission]?
}
