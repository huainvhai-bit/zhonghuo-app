// == Models.swift ==
// 这个文件是 Models/ 模块的入口点
// 导入所有子模型类型，确保它们在一个 module 中可用

import Foundation

// MARK: - 导出所有模型类型（使它们在项目中可见）
public struct Models {
    // Empty wrapper - just ensures all models are in the same module
}

// 导入子模块（这会让 Xcode 知道这些文件是同一个 module 的一部分）
// 实际上 Swift 不需要显式导入同一 module 的文件，但这样可以确保正确编译
