---
title: "浅析Jetbrains的产品版本和更新API设计"
date: 2023-07-28
tags: ["api", "设计", "jetbrains"]
draft: false
---
## 接口分析

### 单个产品信息接口

首先我们通过http抓包来看DataGrip这个产品查询接口，访问的接口地址为下面这个地址

`https://data.services.jetbrains.com/products?code=DG&release.type=eap,rc,release&fields=distributions,link,name,releases&_=1690557030459`

从接口上我们能看到有下面几个方面：

+ graphql风格接口设计。
+ 支持产品代码、软件包通道、软件平台的筛选。主要有下面几个：

  | 平台         | 说明          |
  | ------------ | ------------- |
  | Windows      |               |
  | linux        |               |
  | windowsZip   | windows压缩包 |
  | windowsARM64 |               |
  | mac          |               |
  | macM1        |               |

  该接口返回信息如下：
```json
{
    "DG": [
        {
            "date": "2023-07-20",
            "type": "release",
            "downloads": {
                "linuxARM64": {
                    "link": "https://download.jetbrains.com/datagrip/datagrip-2023.2-aarch64.tar.gz",
                    "size": 570768510,
                    "checksumLink": "https://download.jetbrains.com/datagrip/datagrip-2023.2-aarch64.tar.gz.sha256"
                },
                "linux": {
                    "link": "https://download.jetbrains.com/datagrip/datagrip-2023.2.tar.gz",
                    "size": 569402212,
                    "checksumLink": "https://download.jetbrains.com/datagrip/datagrip-2023.2.tar.gz.sha256"
                },
                "thirdPartyLibrariesJson": {
                    "link": "https://resources.jetbrains.com/storage/third-party-libraries/datagrip/datagrip-2023.2-third-party-libraries.json",
                    "size": 62706,
                    "checksumLink": "https://resources.jetbrains.com/storage/third-party-libraries/datagrip/datagrip-2023.2-third-party-libraries.json.sha256"
                },
                "windows": {
                    "link": "https://download.jetbrains.com/datagrip/datagrip-2023.2.exe",
                    "size": 447884488,
                    "checksumLink": "https://download.jetbrains.com/datagrip/datagrip-2023.2.exe.sha256"
                },
                "windowsZip": {
                    "link": "https://download.jetbrains.com/datagrip/datagrip-2023.2.win.zip",
                    "size": 566939835,
                    "checksumLink": "https://download.jetbrains.com/datagrip/datagrip-2023.2.win.zip.sha256"
                },
                "windowsARM64": {
                    "link": "https://download.jetbrains.com/datagrip/datagrip-2023.2-aarch64.exe",
                    "size": 430945096,
                    "checksumLink": "https://download.jetbrains.com/datagrip/datagrip-2023.2-aarch64.exe.sha256"
                },
                "mac": {
                    "link": "https://download.jetbrains.com/datagrip/datagrip-2023.2.dmg",
                    "size": 542649736,
                    "checksumLink": "https://download.jetbrains.com/datagrip/datagrip-2023.2.dmg.sha256"
                },
                "macM1": {
                    "link": "https://download.jetbrains.com/datagrip/datagrip-2023.2-aarch64.dmg",
                    "size": 534462645,
                    "checksumLink": "https://download.jetbrains.com/datagrip/datagrip-2023.2-aarch64.dmg.sha256"
                }
            },
            "patches": {
                "win": [
                    {
                        "fromBuild": "231.9011.35",
                        "link": "https://download.jetbrains.com/datagrip/DB-231.9011.35-232.8660.111-patch-win.jar",
                        "size": 405126814,
                        "checksumLink": "https://download.jetbrains.com/datagrip/DB-231.9011.35-232.8660.111-patch-win.jar.sha256"
                    },
                    {
                        "fromBuild": "232.8660.88",
                        "link": "https://download.jetbrains.com/datagrip/DB-232.8660.88-232.8660.111-patch-win.jar",
                        "size": 25446054,
                        "checksumLink": "https://download.jetbrains.com/datagrip/DB-232.8660.88-232.8660.111-patch-win.jar.sha256"
                    }
                ],
                "mac": [
                    {
                        "fromBuild": "231.9011.35",
                        "link": "https://download.jetbrains.com/datagrip/DB-231.9011.35-232.8660.111-patch-mac.jar",
                        "size": 386287057,
                        "checksumLink": "https://download.jetbrains.com/datagrip/DB-231.9011.35-232.8660.111-patch-mac.jar.sha256"
                    },
                    {
                        "fromBuild": "232.8660.88",
                        "link": "https://download.jetbrains.com/datagrip/DB-232.8660.88-232.8660.111-patch-mac.jar",
                        "size": 24338594,
                        "checksumLink": "https://download.jetbrains.com/datagrip/DB-232.8660.88-232.8660.111-patch-mac.jar.sha256"
                    }
                ],
                "unix": [
                    {
                        "fromBuild": "231.9011.35",
                        "link": "https://download.jetbrains.com/datagrip/DB-231.9011.35-232.8660.111-patch-unix.jar",
                        "size": 402009513,
                        "checksumLink": "https://download.jetbrains.com/datagrip/DB-231.9011.35-232.8660.111-patch-unix.jar.sha256"
                    },
                    {
                        "fromBuild": "232.8660.88",
                        "link": "https://download.jetbrains.com/datagrip/DB-232.8660.88-232.8660.111-patch-unix.jar",
                        "size": 23828783,
                        "checksumLink": "https://download.jetbrains.com/datagrip/DB-232.8660.88-232.8660.111-patch-unix.jar.sha256"
                    }
                ]
            },
            "notesLink": "https://www.jetbrains.com/datagrip/whatsnew/",
            "licenseRequired": true,
            "version": "2023.2",
            "majorVersion": "2023.2",
            "build": "232.8660.111",
            "whatsnew": "<img src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/updatedialog_600x130_DataGrip-2x-6.png\" alt=\"DataGrip 2023.2 released\" width=\"635\" border=\"0\"> \n<p>To learn more about new features and all the other improvements introduced in version 2023.2 please visit our <a href=\"https://www.jetbrains.com/datagrip/whatsnew/\">What's New page</a>.</p> \n<p></p> \n<h3>User Interface</h3> \n<ul> \n <li>New UI: The toolbar icons have been moved to the header:</li> \n</ul> \n<img class=\"alignnone size-large wp-image-123893\" src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/New-UI-toolbar-default.png\" alt=\"\" width=\"635\" height=\"\" border=\"0\">\n<p></p> \n<ul> \n <li>Improved main toolbar customization</li> \n <li>Light theme with light header in the new UI</li> \n <li>Colored project headers in the new UI</li> \n <li>New UI for schema migration dialog</li> \n</ul> \n<h3>Artificial Intelligence - Limited access</h3> \n<ul> \n <li>AI Assistant (Beta)</li> \n <li><i>AI Actions</i> submenu</li> \n</ul> \n<img class=\"alignnone size-large wp-image-123893\" src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/AI.png\" alt=\"\" width=\"635\" height=\"\" border=\"0\">\n<p></p> \n<h3>Connectivity</h3> \n<ul> \n <li>[Redis] Support for Redis Cluster</li> \n</ul> \n<img class=\"alignnone size-large wp-image-123893\" src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/image-11.png\" alt=\"\" width=\"635\" height=\"\" border=\"0\">\n<p></p> \n<ul> \n <li>[Redshift] Support for external databases and datashares</li> \n <li>More options for connecting with SSL certificates</li> \n <li>HTTP proxy</li> \n <li>Time stamp of the last refresh</li> \n</ul> \n<h3>Data editor</h3> \n<ul> \n <li>Time zones</li> \n</ul> \n<img class=\"alignnone size-large wp-image-123893\" src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/timeZones-2.png\" alt=\"\" width=\"635\" height=\"\" border=\"0\">\n<p></p> \n<ul> \n <li>Preview in settings</li> \n <li><i>Show all columns</i> action to help you find any columns that you may have hidden before</li> \n</ul> \n<h3>Navigation</h3> \n<ul> \n <li>Text search in <i>Search Everywhere</i></li> \n</ul> \n<img class=\"alignnone size-large wp-image-123893\" src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/TextSearch.png\" alt=\"\" width=\"635\" height=\"\" border=\"0\">\n<p></p> \n<h3>Coding assistance</h3> \n<ul> \n <li>New settings for qualifying objects</li> \n</ul> \n<img class=\"alignnone size-large wp-image-123893\" src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/Qualification.png\" alt=\"\" width=\"635\" height=\"\" border=\"0\">\n<p></p> \n<ul> \n <li>Syntax highlighting in inspection descriptions</li> \n</ul> \n<h3><i>Files</i> tool window</h3> \n<ul> \n <li>Sort by modification time</li> \n</ul> \n<img class=\"alignnone size-large wp-image-123893\" src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/SortByTime-1.png\" alt=\"\" width=\"635\" height=\"\" border=\"0\">\n<p></p> \n<ul> \n <li>Open folders with a single click</li> \n <li>Hiding scratches and consoles</li> \n</ul> \n<h3>Other</h3> \n<ul> \n <li>WSL support for dump tools</li> \n <li><i>Modify</i> UI: List of objects of the same kind</li> \n</ul> \n<img class=\"alignnone size-large wp-image-123893\" src=\"https://blog.jetbrains.com/wp-content/uploads/2023/07/Modify.png\" alt=\"\" width=\"635\" height=\"\" border=\"0\">\n<p></p>",
            "uninstallFeedbackLinks": {
                "linuxARM64": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "windowsJBR8": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "windowsZipJBR8": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "linux": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "thirdPartyLibrariesJson": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "windows": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "windowsZip": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "windowsARM64": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "linuxJBR8": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "mac": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "macJBR8": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2",
                "macM1": "https://www.jetbrains.com/datagrip/uninstall/?edition=2023.2"
            },
            "printableReleaseType": null
        }
    ]
}
```

从返回上看，返回记录内容主要有那么几个方面：

+ 软件完整包的下载链接。包含的信息有前面查询中的通道、发布日期、不同平台的软件包下载链接、大小及文件校验。

+ 补丁包的下载链接。包含不同平台的补丁包Patch下载路径，以及应用到的版本、补丁包大小、补丁包文件校验信息。同时补丁包的命名上也是采用{fromversion}-{updateversion}这样的文件名，更加清晰地说明了文件更新的版本结果。

  > 注：我曾经使用jetbrains其他版本的产品进行自我更新，更新的逻辑是自动选取当前版本的补丁，升级后再进行迭代升级。

+ 更新日志。
+ 主版本。
+ 新特性介绍页。
+ 卸载反馈页面地址。
  ### 产品列表信息接口

  再来看产品列表接口信息，接口如下：

  `https://data.services.jetbrains.com/products/releases?code=SPA,FL,TBA,IIU,PCP,WS,PS,RS,RD,CL,,DS,DG,RM,GO,RC,DPK,DP,DM,DC,YTD,TC,HB,,MPS,PCE,IIE,,,,,&latest=true&type=release&build=&_=1690557716168`

  接口包含了主要的产品代码，返回信息如下：

  ```json
  {
      "RS": [
          {
              "date": "2023-07-18",
              "type": "release",
              "downloads": {
                  "windowsWeb": {
                      "link": "https://download.jetbrains.com/resharper/dotUltimate.2023.1.4/JetBrains.ReSharper.2023.1.4.web.exe",
                      "size": 46379168,
                      "checksumLink": "https://download.jetbrains.com/resharper/dotUltimate.2023.1.4/JetBrains.ReSharper.2023.1.4.web.exe.sha256"
                  },
                  "thirdPartyLibrariesJson": {
                      "link": "https://resources.jetbrains.com/storage/third-party-libraries/dotnet/JetBrains.ReSharper-2023.1.4-third-party-libraries.json",
                      "size": 31001,
                      "checksumLink": "https://resources.jetbrains.com/storage/third-party-libraries/dotnet/JetBrains.ReSharper-2023.1.4-third-party-libraries.json.sha256"
                  }
              },
              "patches": {},
              "notesLink": "https://youtrack.jetbrains.com/issues/RSRP?q=available%20in:%202023.1.4%20",
              "licenseRequired": null,
              "version": "2023.1.4",
              "majorVersion": "2023.1",
              "build": "2023.1.4.65536",
              "whatsnew": "<p>In view of the discontinued support of JavaScript, TypeScript and CSS, ReSharper no longer blocks Visual Studio IntelliSense from providing code completion, typing assistance, and parameter info for those languages in Razor/Blazor and HTML files. </p> \n<p>Relevant issues resolved:</p> \n<ol> \n <li>Allow Visual Studio IntelliSense to be shown on JavaScript and CSS script blocks in <code>.cshtml</code> files.[<a href=\"https://youtrack.jetbrains.com/issue/RSRP-490852\">RSRP-490852</a>]&nbsp;</li> \n <li>&nbsp;Enable ReSharper completion in C# code inside an HTML tag in Razor projects.[<a href=\"https://youtrack.jetbrains.com/issue/RSRP-493151\">RSRP-493151</a>]</li> \n <li>ReSharper makes VS IntelliSense omit closing curly braces for CSS / JS / TS blocks inside <code>.cshtml</code> Razor files. [<a href=\"https://youtrack.jetbrains.com/issue/RSRP-492643\">RSRP-492643</a>]&nbsp;</li> \n <li>&nbsp;ReSharper shows its own completion for Class selectors in CSS and blocks VS IntelliSense. [<a href=\"https://youtrack.jetbrains.com/issue/RSRP-492642\">RSRP-492642</a>]</li> \n <li>ReSharper blocks IntelliSense for CSS classes in Blazor projects. [<a href=\"https://youtrack.jetbrains.com/issue/RSRP-492986\">RSRP-492986</a>]</li> \n <li>Code completion suggestions are doubled in Razor files. [<a href=\"https://youtrack.jetbrains.com/issue/RSRP-493095\">RSRP-493095</a>]</li> \n</ol>",
              "uninstallFeedbackLinks": null,
              "printableReleaseType": null
          }
      ],
      "PS": [
          {
              "date": "2023-07-17",
              "type": "release",
              "downloads": {
                  "linuxARM64": {
                      "link": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4-aarch64.tar.gz",
                      "size": 645475495,
                      "checksumLink": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4-aarch64.tar.gz.sha256"
                  },
                  "linux": {
                      "link": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4.tar.gz",
                      "size": 648953340,
                      "checksumLink": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4.tar.gz.sha256"
                  },
                  "thirdPartyLibrariesJson": {
                      "link": "https://resources.jetbrains.com/storage/third-party-libraries/webide/PhpStorm-2023.1.4-third-party-libraries.json",
                      "size": 71604,
                      "checksumLink": "https://resources.jetbrains.com/storage/third-party-libraries/webide/PhpStorm-2023.1.4-third-party-libraries.json.sha256"
                  },
                  "windows": {
                      "link": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4.exe",
                      "size": 459658368,
                      "checksumLink": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4.exe.sha256"
                  },
                  "windowsZip": {
                      "link": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4.win.zip",
                      "size": 637976278,
                      "checksumLink": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4.win.zip.sha256"
                  },
                  "windowsARM64": {
                      "link": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4-aarch64.exe",
                      "size": 453258792,
                      "checksumLink": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4-aarch64.exe.sha256"
                  },
                  "mac": {
                      "link": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4.dmg",
                      "size": 616414308,
                      "checksumLink": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4.dmg.sha256"
                  },
                  "macM1": {
                      "link": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4-aarch64.dmg",
                      "size": 607324942,
                      "checksumLink": "https://download.jetbrains.com/webide/PhpStorm-2023.1.4-aarch64.dmg.sha256"
                  }
              },
              "patches": {
                  "win": [
                      {
                          "fromBuild": "231.9225.7",
                          "link": "https://download.jetbrains.com/webide/PS-231.9225.7-231.9225.18-patch-win.jar",
                          "size": 43742381,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-231.9225.7-231.9225.18-patch-win.jar.sha256"
                      },
                      {
                          "fromBuild": "231.9161.47",
                          "link": "https://download.jetbrains.com/webide/PS-231.9161.47-231.9225.18-patch-win.jar",
                          "size": 43764536,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-231.9161.47-231.9225.18-patch-win.jar.sha256"
                      },
                      {
                          "fromBuild": "223.8836.42",
                          "link": "https://download.jetbrains.com/webide/PS-223.8836.42-231.9225.18-patch-win.jar",
                          "size": 170935547,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-223.8836.42-231.9225.18-patch-win.jar.sha256"
                      }
                  ],
                  "mac": [
                      {
                          "fromBuild": "231.9225.7",
                          "link": "https://download.jetbrains.com/webide/PS-231.9225.7-231.9225.18-patch-mac.jar",
                          "size": 42714062,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-231.9225.7-231.9225.18-patch-mac.jar.sha256"
                      },
                      {
                          "fromBuild": "231.9161.47",
                          "link": "https://download.jetbrains.com/webide/PS-231.9161.47-231.9225.18-patch-mac.jar",
                          "size": 42737387,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-231.9161.47-231.9225.18-patch-mac.jar.sha256"
                      },
                      {
                          "fromBuild": "223.8836.42",
                          "link": "https://download.jetbrains.com/webide/PS-223.8836.42-231.9225.18-patch-mac.jar",
                          "size": 170052372,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-223.8836.42-231.9225.18-patch-mac.jar.sha256"
                      }
                  ],
                  "unix": [
                      {
                          "fromBuild": "231.9225.7",
                          "link": "https://download.jetbrains.com/webide/PS-231.9225.7-231.9225.18-patch-unix.jar",
                          "size": 42086051,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-231.9225.7-231.9225.18-patch-unix.jar.sha256"
                      },
                      {
                          "fromBuild": "231.9161.47",
                          "link": "https://download.jetbrains.com/webide/PS-231.9161.47-231.9225.18-patch-unix.jar",
                          "size": 42108348,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-231.9161.47-231.9225.18-patch-unix.jar.sha256"
                      },
                      {
                          "fromBuild": "223.8836.42",
                          "link": "https://download.jetbrains.com/webide/PS-223.8836.42-231.9225.18-patch-unix.jar",
                          "size": 170087580,
                          "checksumLink": "https://download.jetbrains.com/webide/PS-223.8836.42-231.9225.18-patch-unix.jar.sha256"
                      }
                  ]
              },
              "notesLink": "https://youtrack.jetbrains.com/articles/WI-A-231736068/PhpStorm-2023.1.4-231.9225.18-build-Release-Notes",
              "licenseRequired": true,
              "version": "2023.1.4",
              "majorVersion": "2023.1",
              "build": "231.9225.18",
              "whatsnew": "<h3 class=\"\">PhpStorm 2023.1.4 is now available</h3> \n<br>\n<br> \n<p>This build brings a bunch of bug fixes and quality-of-life improvements.</p> \n<p>Notable changes:</p> \n<div id=\"content\"> \n</div> \n<ul> \n <li>\"Copy Reference\" on a line in Editor no longer copies \"Path From Content Root\" (instead it copies the path from the parent root e.g. source root, test root) [<a href=\"https://youtrack.jetbrains.com/issue/IDEA-316752\">IDEA-316752</a>] </li> \n <li>File Cache Conflict when using an external formatter since 2023.1.1 [<a href=\"https://youtrack.jetbrains.com/issue/WI-72733\">WI-72733</a>] </li> \n <li>File cache conflict when use External Formatter and live template in interface [<a href=\"https://youtrack.jetbrains.com/issue/WI-73178\">WI-73178</a>] </li> \n <li>IDE start fails with \"CannotActivateException: Address already in use: bind\" [<a href=\"https://youtrack.jetbrains.com/issue/IDEA-323836\">IDEA-323836</a>] </li> \n</ul> \n<p><br></p> \n<p class=\"\"> For the full list of changes in this build, please see the <a href=\"https://youtrack.jetbrains.com/articles/WI-A-231736068\">release notes</a>. </p>",
              "uninstallFeedbackLinks": {
                  "linuxARM64": "https://www.jetbrains.com/phpstorm/uninstall/?version=2023.1.4",
                  "linux": "https://www.jetbrains.com/phpstorm/uninstall/?version=2023.1.4",
                  "thirdPartyLibrariesJson": "https://www.jetbrains.com/phpstorm/uninstall/?version=2023.1.4",
                  "windows": "https://www.jetbrains.com/phpstorm/uninstall/?version=2023.1.4",
                  "windowsZip": "https://www.jetbrains.com/phpstorm/uninstall/?version=2023.1.4",
                  "windowsARM64": "https://www.jetbrains.com/phpstorm/uninstall/?version=2023.1.4",
                  "mac": "https://www.jetbrains.com/phpstorm/uninstall/?version=2023.1.4",
                  "macM1": "https://www.jetbrains.com/phpstorm/uninstall/?version=2023.1.4"
              },
              "printableReleaseType": null
          }
      ],
      ...............省略..............
      ]
  }
  ```

  返回跟单个产品类似，只不过是上面的超集。

## 总结

通过Jetbrains的接口设计我们可以看出jetbrains的版本和更新设计主要是功能和实用性上的考量。主要包含下面的几个部分：

1. 最新的安装包信息。可以通过接口下载最新的不同平台的软件包。
2. 软件更新包。产品可以通过接口下载和检查更新补丁的有效性。
3. 同时提供软件更新及软件安装时界面上的交互及新功能的说明。

## 参考阅读

+ [云风《游戏数据包的补丁和更新》](https://blog.codingnow.com/2023/11/vfs_patch.html)
+ [tailscale的更新相关代码](https://github.com/tailscale/tailscale/tree/main/clientupdate)