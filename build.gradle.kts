plugins {
    id("org.springframework.boot") version "3.5.6"
    id("io.spring.dependency-management") version "1.1.7"
    kotlin("jvm") version "2.2.0"
    kotlin("plugin.spring") version "2.2.0"
    kotlin("plugin.jpa") version "2.2.0"
    kotlin("kapt") version "2.2.0"
}

group = "com.aifactory"
version = "0.0.1-SNAPSHOT"
description = "competition"

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

repositories {
    mavenCentral()
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter")
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    // Kotlin 관련
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("org.jetbrains.kotlin:kotlin-reflect")

    // QueryDSL
    implementation("io.github.openfeign.querydsl:querydsl-jpa:6.11")
    implementation("io.github.openfeign.querydsl:querydsl-core:6.11")
    kapt("io.github.openfeign.querydsl:querydsl-apt:6.11:jpa")

    // Database
    runtimeOnly("org.postgresql:postgresql")

    // Logging
    implementation("net.logstash.logback:logstash-logback-encoder:8.0")

    // Swagger/OpenAPI
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.2.0")
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-api:2.2.0")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.jetbrains.kotlin:kotlin-test-junit5")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.test {
    useJUnitPlatform()
}

kotlin {
    jvmToolchain(21)

    compilerOptions {
        freeCompilerArgs.add("-Xjsr305=strict")
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21)
    }
}

// QueryDSL Q클래스 생성 경로 설정
kapt {
    generateStubs = true
}

// Generated 소스 경로 추가
sourceSets {
    main {
        kotlin.srcDirs("src/main/kotlin", "build/generated/source/kapt/main")
    }
}
