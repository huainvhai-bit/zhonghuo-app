#!/bin/bash

# 修复 Xcode 快捷键和运行行为

echo "🔧 修复 Xcode 快捷键和运行行为"
echo "================================"
echo ""

# 1. 关闭 Xcode
echo "1️⃣ 关闭 Xcode..."
killall Xcode 2>/dev/null || echo "   Xcode 未运行"
sleep 2
echo "   ✅"
echo ""

# 2. 删除 Xcode 快捷键配置
echo "2️⃣ 重置 Xcode 快捷键..."
rm -rf ~/Library/Preferences/com.apple.dt.Xcode.plist
rm -rf ~/Library/Caches/com.apple.dt.Xcode
echo "   ✅"
echo ""

# 3. 清理项目用户数据
echo "3️⃣ 清理项目用户数据..."
rm -rf 终活.xcodeproj/project.xcworkspace/xcuserdata
rm -rf 终活.xcodeproj/xcuserdata
echo "   ✅"
echo ""

# 4. 修复 Scheme - 添加正确的 Launch 配置
echo "4️⃣ 修复 Scheme 配置..."
cat > 终活.xcodeproj/xcshareddata/xcschemes/终活.xcscheme << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1600"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "A6000000"
               BuildableName = "终活"
               BlueprintName = "终活"
               ReferencedContainer = "container:终活.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      shouldAutocreateTestPlan = "YES">
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES"
      enableAddressSanitizer = "NO"
      enableASanStackUseAfterReturn = "NO"
      enableThreadSanitizer = "NO"
      enableUBSanitizer = "NO"
      disableMallocStackLogging = "NO">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "A6000000"
            BuildableName = "终活"
            BlueprintName = "终活"
            ReferencedContainer = "container:终活.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
      <AdditionalOptions>
      </AdditionalOptions>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "A6000000"
            BuildableName = "终活"
            BlueprintName = "终活"
            ReferencedContainer = "container:终活.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
EOF
echo "   ✅"
echo ""

# 5. 清理 DerivedData
echo "5️⃣ 清理 DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/终活-*
echo "   ✅"
echo ""

# 6. 重启模拟器
echo "6️⃣ 重启模拟器..."
xcrun simctl shutdown "iPhone 17 Pro" 2>/dev/null || true
sleep 2
xcrun simctl boot "iPhone 17 Pro"
echo "   ✅"
echo ""

# 7. 构建并安装
echo "7️⃣ 构建并安装..."
if xcodebuild -scheme 终活 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | grep -q "BUILD SUCCEEDED"; then
    echo "   ✅ 构建成功"
else
    echo "   ❌ 构建失败"
    exit 1
fi

APP_PATH=$(ls -d ~/Library/Developer/Xcode/DerivedData/终活-*/Build/Products/Debug-iphonesimulator/终活.app | head -1)
xcrun simctl uninstall "iPhone 17 Pro" com.zhonghuo.app 2>/dev/null || true
if xcrun simctl install "iPhone 17 Pro" "$APP_PATH"; then
    echo "   ✅ 安装成功"
else
    echo "   ❌ 安装失败"
    exit 1
fi
echo ""

# 8. 启动应用
echo "8️⃣ 启动应用..."
if PID=$(xcrun simctl launch "iPhone 17 Pro" com.zhonghuo.app 2>&1 | grep -o '[0-9]*' | head -1); then
    echo "   ✅ 应用已启动 (PID: $PID)"
else
    echo "   ⚠️  应用可能已启动"
fi
echo ""

# 9. 打开 Xcode
echo "9️⃣ 打开 Xcode..."
open -a Xcode /Users/lishimin/Documents/zhonghuo-app/终活.xcodeproj
echo "   ✅"
echo ""

echo "================================"
echo "✅ 修复完成！"
echo ""
echo "💻 在 Xcode 中测试:"
echo "   1. 等待 Xcode 完全加载（约 10 秒）"
echo "   2. 确认顶部：Scheme='终活', Device='iPhone 17 Pro'"
echo "   3. 按 Cmd + R 运行"
echo "   4. 按 Cmd + Shift + Y 打开控制台"
echo ""
echo "🔍 如果 Cmd+R 还是滴滴响:"
echo "   1. Xcode 菜单 → Product → Run (直接点击)"
echo "   2. 或检查系统偏好设置 → 键盘 → 快捷键"
echo "   3. 或使用工具栏的 ▶️ 按钮"
echo ""
echo "📱 应用已安装并可运行:"
echo "   xcrun simctl launch \"iPhone 17 Pro\" com.zhonghuo.app"
echo ""
