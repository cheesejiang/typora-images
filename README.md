# Windows PowerShell + GitHub Public 仓库 + Typora 自定义上传命令。


## 一、创建 GitHub 图床仓库

打开 [GitHub 创建仓库](https://github.com/new?utm_source=chatgpt.com)。

建议配置：

| 配置项             | 内容                   |
| --------------- | -------------------- |
| Repository name | `typora-images`      |
| Description     | Typora image hosting |
| Visibility      | Public               |
| Add README      | 可勾选                  |

创建完成后，仓库结构可以是：

```
typora-images/
├── README.md
└── images/
```

`images` 文件夹可以先不创建，第一次上传时脚本会自动创建。

注意：Public 仓库中的图片任何人都可以访问，不要放公司内部截图或敏感资料。

## 二、创建 GitHub Token

进入 [Fine-grained Personal Access Token](https://github.com/settings/personal-access-tokens/new?utm_source=chatgpt.com)。

设置：

| 配置项                   | 内容                       |
| --------------------- | ------------------------ |
| Token name            | `typora-image-upload`    |
| Expiration            | 建议 90 days               |
| Repository access     | Only select repositories |
| Selected repositories | `typora-images`          |

在 Permissions 中添加：

| 权限       | 设置             |
| -------- | -------------- |
| Contents | Read and write |
| Metadata | Read-only      |

点击 `Generate token`，复制生成的 Token。


## 三、准备 PowerShell 上传脚本

下载 typora-github-upload.ps1

将它放在：

```
C:\Users\用户名\Scripts\typora-github-upload.ps1
```

用记事本打开，修改文件开头：

```
$GitHubOwner = "你的GitHub用户名"
$GitHubRepo  = "typora-images"
$GitHubBranch = "main"
$ImageFolder = "images"
```

例如：

```
$GitHubOwner = "cheesejiang"
$GitHubRepo  = "typora-images"
$GitHubBranch = "main"
$ImageFolder = "images"
```

保存。

## 四、保存 Token

打开 Windows PowerShell，执行：

```
$dir = Join-Path $env:APPDATA "TyporaGitHub"

New-Item -ItemType Directory -Force -Path $dir | Out-Null

Read-Host "请输入 GitHub Token" -AsSecureString |
    ConvertFrom-SecureString |
    Set-Content -NoNewline (Join-Path $dir "token.txt")
```

粘贴刚刚生成的 Token。

这个方式使用 Windows 当前账户的 DPAPI 保护 Token，其他 Windows 用户通常无法解密。

## 五、先单独测试上传

先不要急着配置 Typora。

在 PowerShell 中执行：

```
Test-Path "C:\Users\a\Scripts\typora-github-upload.ps1"
```

返回 `True` 才继续。

然后测试上传一张图片：

```
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass `
  -File "C:\Users\a\Scripts\typora-github-upload.ps1" `
  "C:\Users\a\AppData\Local\Temp\Typora\typora-icon.png"
```

注意路径使用单个反斜杠 `\`。

成功时应该输出类似：

```
https://raw.githubusercontent.com/用户名/typora-images/main/images/typora-icon_xxx.png
```

把 URL 复制到浏览器无痕窗口，确认能打开。

如果失败，根据报错检查：

- `401`：Token 无效或过期。
- `403`：Token 权限不足，或仓库策略限制。
- `404`：仓库用户名、仓库名或分支名不正确。
- 网络超时：检查 Windows 网络连接。

## 六、配置 Typora

打开：

`文件 → 偏好设置 → 图像`

按照下面设置：

| 设置项           | 正确配置  |
| ------------- | ----- |
| 图片插入规则        | 上传图片  |
| 本地位置图片应用规则    | 勾选    |
| 网络位置图片应用规则    | 暂时不勾选 |
| YAML 自动上传     | 不勾选   |
| 上传服务          | 自定义命令 |
| 插入时自动转义图片 URL | 暂时不勾选 |

自定义命令填写：

```
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "C:\Users\a\Scripts\typora-github-upload.ps1"
```

这里不要手动添加图片路径，Typora 会自动追加。

然后点击「验证图片上传选项」。

## 七、最终测试

在 Typora 中复制一张普通截图，按 `Ctrl + V`。

正常情况下，Typora 会把本地图片上传到 GitHub，并将 Markdown 转换成：

```
![图片](https://raw.githubusercontent.com/用户名/typora-images/main/images/图片名.png)
```

然后使用浏览器无痕窗口打开图片链接。

如果可以正常显示，整个图床就配置完成了。


## 最终检查清单

配置进度

0/8

GitHub 创建 typora-images 仓库，并设置为 Public

创建 Fine-grained Token，授予 Contents Read and write

PowerShell 脚本填写正确的 GitHub 用户名和仓库名

Token 已安全保存到 Windows 用户目录

PowerShell 单独上传图片成功

Typora 已配置自定义命令

Typora 粘贴截图后自动上传成功

无痕浏览器可以打开图片链接
