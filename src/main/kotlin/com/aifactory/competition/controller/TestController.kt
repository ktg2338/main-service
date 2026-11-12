package com.aifactory.competition.controller

import org.springframework.http.HttpHeaders
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestHeader

import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController


@RestController
@RequestMapping("/competition")
class TestController {

    @PostMapping("profile")
    fun profile(
        @RequestHeader headers: HttpHeaders
    ){
        // 모든 헤더 로그 출력
        headers.forEach { name, values ->
            println("Header: $name = ${values.joinToString(", ")}")
        }


    }
}