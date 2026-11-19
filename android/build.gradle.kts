import java.io.File

buildscript {
    // buildscript 仓库由全局 init 脚本 (aliyun-mirror.gradle) 注入阿里云镜像
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.9.0")
    }
}

// 项目依赖仓库由 settings.gradle.kts 的 dependencyResolutionManagement 统一管理
rootProject.buildDir = File("../build")
subprojects {
    project.buildDir = File("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}