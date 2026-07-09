//
//  Post.swift
//  InstagramClone
//
//  Created by Ahmad on 25/06/2026.
//


import Foundation

struct Post {
    var id: String
    var username: String
    var userImage: String
    var postImage: String
    var likesCount: String
    var caption: String
    var timeAgo: String
    var isLiked: Bool // لمعرفة هل المستخدم الحالي عامل لايك
}
