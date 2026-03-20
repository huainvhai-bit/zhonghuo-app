#!/bin/bash
# 修复 DeviceMonitor - 注释掉模拟器不支持的功能

cd /Users/lishimin/Documents/zhonghuo-app

echo "🔧 修复 DeviceMonitor..."

# 备份
cp DeviceMonitor.swift DeviceMonitor.swift.bak

# 注释 queryPedometerData 调用
sed -i '' 's/CMPedometer\.queryPedometerData/\/\/ CMPedometer.queryPedometerData/' DeviceMonitor.swift
sed -i '' 's/guard let self = self else { return }/\/\/ guard let self = self else { return }/' DeviceMonitor.swift
sed -i '' 's/if let error = error {/\/\/ if let error = error {/' DeviceMonitor.swift
sed -i '' 's/print("❌ 获取步数失败/\/\/ print("❌ 获取步数失败/' DeviceMonitor.swift
sed -i '' 's/return/\/\/ return/' DeviceMonitor.swift
sed -i '' 's/if let data = pedometerData {/\/\/ if let data = pedometerData {/' DeviceMonitor.swift
sed -i '' 's/DispatchQueue\.main\.async {/\/\/ DispatchQueue.main.async {/' DeviceMonitor.swift
sed -i '' 's/self\.stepCount = data\.numberOfSteps\.intValue/\/\/ self.stepCount = data.numberOfSteps.intValue/' DeviceMonitor.swift
sed -i '' 's/self\.lastUpdateTime = Date()/\/\/ self.lastUpdateTime = Date()/' DeviceMonitor.swift
sed -i '' 's/}/\/\/ }/' DeviceMonitor.swift

echo "✅ DeviceMonitor 已修复（模拟器模式）"
echo ""
echo "⚠️  步数功能在模拟器上暂时显示为 0"
echo "   真机上需要取消注释"
echo ""
