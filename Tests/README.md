# 终活 App 单元测试

## 运行测试

```bash
xcodebuild test -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 测试文件结构

- `ZhonghuoTests/` - 主测试目标
  - `Models/` - 数据模型测试
  - `Managers/` - 业务逻辑测试
  - `Views/` - UI 视图测试

## 测试覆盖率目标

- 模型层：80%
- 业务逻辑层：70%
- UI 层：50%
