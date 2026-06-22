#!/usr/bin/env node

/**
 * HarmonyOS 签名自动配置初始化脚本
 * 用于快速初始化签名配置
 */

import * as path from 'path';
import * as fs from 'fs-extra';
import { SignatureDetector } from './detector';
import { SignatureGenerator } from './generator';
import { TemplateEngine } from './template-engine';

async function main() {
  console.log('🚀 HarmonyOS 签名自动配置初始化\n');

  const projectPath = process.cwd();
  const detector = new SignatureDetector();
  const generator = new SignatureGenerator();
  const templateEngine = new TemplateEngine();

  try {
    // 1. 检查当前签名状态
    console.log('📋 步骤 1: 检查签名配置状态...');
    const status = await detector.checkSignatureConfig(projectPath);
    console.log(`   状态: ${status.status}`);
    console.log(`   消息: ${status.message}\n`);

    // 2. 如果需要，生成签名文件
    if (status.status === 'not_configured' || status.status === 'file_missing') {
      console.log('🔐 步骤 2: 生成调试签名...');
      const signature = await generator.generateDebugSignature(projectPath, {
        buildMode: 'debug',
        configName: 'default',
        overwrite: false
      });
      console.log(`   ✅ 签名文件已生成: ${signature.filePath}\n`);
    } else {
      console.log('✅ 步骤 2: 签名已配置，跳过生成\n');
    }

    // 3. 创建环境配置文件
    console.log('⚙️  步骤 3: 创建环境配置文件...');
    
    const envExamplePath = path.join(projectPath, '.env.example');
    if (!await fs.pathExists(envExamplePath)) {
      await templateEngine.applyTemplate('env', envExamplePath);
      console.log('   ✅ 已创建 .env.example');
    }

    const envDevPath = path.join(projectPath, '.env.development');
    if (!await fs.pathExists(envDevPath)) {
      await fs.writeFile(envDevPath, 
        `# HarmonyOS 签名配置 - 开发环境\n` +
        `HARMONYOS_ENV=development\n` +
        `HARMONYOS_SIGNATURE_PATH=./.signature/debug.p12\n` +
        `HARMONYOS_BUILD_MODE=debug\n`
      );
      console.log('   ✅ 已创建 .env.development');
    }

    const envProdPath = path.join(projectPath, '.env.production');
    if (!await fs.pathExists(envProdPath)) {
      await fs.writeFile(envProdPath,
        `# HarmonyOS 签名配置 - 生产环境\n` +
        `HARMONYOS_ENV=production\n` +
        `# HARMONYOS_SIGNATURE_PATH=/path/to/release.p12\n` +
        `HARMONYOS_BUILD_MODE=release\n`
      );
      console.log('   ✅ 已创建 .env.production');
    }
    console.log('');

    // 4. 更新 .gitignore
    console.log('📝 步骤 4: 更新 .gitignore...');
    const gitignorePath = path.join(projectPath, '.gitignore');
    const gitignoreContent = await templateEngine.getTemplate('gitignore');
    
    if (await fs.pathExists(gitignorePath)) {
      const existingContent = await fs.readFile(gitignorePath, 'utf-8');
      if (!existingContent.includes('.signature/')) {
        await fs.appendFile(gitignorePath, '\n' + gitignoreContent);
        console.log('   ✅ 已更新 .gitignore');
      } else {
        console.log('   ℹ️  .gitignore 已包含签名配置');
      }
    } else {
      await fs.writeFile(gitignorePath, gitignoreContent);
      console.log('   ✅ 已创建 .gitignore');
    }
    console.log('');

    // 5. 验证配置
    console.log('✅ 步骤 5: 验证签名配置...');
    const finalStatus = await detector.checkSignatureConfig(projectPath);
    console.log(`   状态: ${finalStatus.status}`);
    console.log(`   消息: ${finalStatus.message}\n`);

    if (finalStatus.status === 'configured') {
      console.log('🎉 签名配置初始化成功！\n');
      console.log('下一步操作:');
      console.log('  1. 运行 hvigorw assembleHap 构建应用');
      console.log('  2. 应用将自动使用生成的调试签名');
      console.log('  3. 生产环境请配置 .env.production 文件\n');
    } else {
      console.log('⚠️  签名配置可能存在问题，请检查上述信息\n');
    }

  } catch (error) {
    console.error('❌ 初始化失败:', error);
    process.exit(1);
  }
}

// 执行主函数
main().catch(console.error);
