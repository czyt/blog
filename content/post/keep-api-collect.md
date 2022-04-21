---
title: "Keep运动接口"
date: 2022-04-21
tags: ["keep", "api"]
draft: false
---

## 基础接口

### 授权

```bash
curl --location --request POST 'https://api.gotokeep.com/v1.1/users/login' \
--header 'Content-Type: application/json' \
--data-raw '{"mobile": 18888888888, "password": "aa"}'
```

返回token内容需要作为后续请求的header传递，返回示例：

```json
{
    "ok": true,
    "data": {
        "userId": "011981111e131",
        "level": 0,
        "goal": 0,
        "gender": "M",
        "token": "xxxxxxxxxxxx",
        "userRegisterInfo": null
    },
    "errorCode": "0",
    "now": "2022-04-21T05:02:57Z",
    "version": "1.0.0",
    "text": null,
    "more": {}
}
```



### 动作库

获取动作分类

```bash
curl --location --request GET 'https://api.gotokeep.com/training/v2/trainingpoints/exerciselib' \
--header 'Authorization: Bearer xxxxxxxxx'
```

返回 

```json
{
    "ok": true,
    "data": [
        {
            "name": "胸部",
            "_id": "54826e417fb786000069ad82",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/55963b0e73800000.png"
        },
        {
            "name": "背部",
            "_id": "54826e417fb786000069ad84",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/55963ab1a4c00000.png"
        },
        {
            "name": "肩部",
            "_id": "54826e417fb786000069ad83",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/55963b1db3c00000.png"
        },
        {
            "name": "手臂",
            "_id": "54826e417fb786000069ad88",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/559639a46e400000.png"
        },
        {
            "name": "颈部",
            "_id": "55cb1b72bfbf17f934371eba",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/55963afccdc00000.png"
        },
        {
            "name": "腹部",
            "_id": "54826e417fb786000069ad86",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/55963b3fc0400000.png"
        },
        {
            "name": "腰部",
            "_id": "55cb1ca06fe674f94036d581",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/55963b2cc0800000.png"
        },
        {
            "name": "臀部",
            "_id": "54826e417fb786000069ad87",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/559639594f800000.png"
        },
        {
            "name": "腿部",
            "_id": "54826e417fb786000069ad85",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/55963ad31b400000.png"
        },
        {
            "name": "全身",
            "_id": "54826e417fb786000069ad81",
            "url": "http://static1.keepcdn.com/misc/2016/08/05/12/559638c467800000.png"
        }
    ],
    "errorCode": 0,
    "text": ""
}
```



获取动作库某个分类下的动作

```bash
curl --location --request GET 'https://api.gotokeep.com/search/v3/exercise?trainingPoints=54826e417fb786000069ad82' \
--header 'Authorization: Bearer xxxxxxxxx'
```



### 动作搜索

```bash
curl --location --request GET 'https://api.gotokeep.com/search/v4/exercise?keyword=坐姿左侧大腿后侧拉伸&limit=20' \
--header 'Authorization: Bearer xxxxxxxx'
```



## 参考

https://github.com/wodewone/keepForMac/blob/master/Doc-api-keep.md

