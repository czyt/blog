---
title: "GIT 别名的 10 个级别【机翻】"
date: 2024-06-25
tags: ["git"]
draft: false
---

# 第一部分：初级到中级概念

> 原文 https://www.eficode.com/blog/10-levels-of-git-aliases-beginner-to-intermediate-concepts

## 您是否知道 Git 可以通过多种方式根据您的需求进行定制？

在 Git 中创建别名是一项强大的功能，它允许您为更长的 Git 命令（以及更多命令）定义“快捷方式”。对于某些人来说，它只是一个让命令行 Git 使用变得可行的工具，但我将向您展示 Git 别名是如此强大，它们可以帮助使命令行成为使用 Git 的首选且最有效的方式。

创建 Git 别名的主要动机可能是以下一项或多项：

- 优化：为常用的 Git 命令创建快捷方式。
- 定制：让 Git 按照您想要的方式运行或支持团队商定的习惯。
- 记忆：易于记忆的复杂操作快捷键。

在我的博客系列的第 1 部分中，我将带您从非常简单的基础知识开始，介绍只需键入较长命令的 Git 别名，一直到甚至许多经验丰富的 Git 老手从未使用过的更高级功能。

第 2 部分将从这里继续，介绍更高级的概念，并尝试真正“外面”使用 Git 别名，包括一些彻头彻尾疯狂的示例，然后再讨论解决相同需求的替代方案。

学习和理解这些技术，无论是用于从别人那里窃取的别名还是自己冒险突破界限，都将使您成为更高效、更强大的 Git 用户，并有望让您使用 Git 的日常生活变得更加愉快。在此过程中，您可能还会学到一些提示和技巧，并探索您甚至不知道的 Git 角落。

## 什么是 Git 别名，我们如何设置它们？

Git 别名是 Git 子命令的替代，就像 Bash 别名是其他 Bash 命令或脚本的替代一样。 Git 只是允许您定义自己的 Git 命令来执行您想要的操作，并且可以与内置命令无缝地使用。

别名是在 Git 配置层次结构中定义的，但由于我们通常希望它们在我们计算机上的任何地方都可以工作，因此全局配置是它们的自然家园。

您可以通过直接编辑全局配置文件或使用`git config`命令来添加别名。

要创建您的第一个简单别名，只需尝试：

```
$ git config --global alias.st status
```

这将在全局配置文件的 [alias] 部分添加一个新行，并创建该部分（如果尚不存在）。我们来看一下：

```
$ cat ~/.gitconfig
[user]
   name = Jan Krag
   email = jan.krag@eficode.com
[alias]
   st = status
```

恭喜，您拥有了第一个别名，现在可以输入：
`git st`

 代替：
`git status`

对于更复杂的别名，在您稍后的旅程中，我建议您只需在首选编辑器中打开 ~/.gitconfig 并直接在其中添加或修改别名即可。

### 第一级：懒惰的打字者

好的，让我们开始第一层。我很懒，只是想优化每天使用数百次的命令输入，或者处理我经常犯的常见拼写错误。

我们已经看到了上面的`st`建议，但这里有一些简单快捷方式的更常见示例：

```
[alias]
    s  = status
    st = status
    c = commit
    sw = switch
    br = branch
```

对于“常见拼写错误”风格的别名，这些是个人偏好。为您的手指无法输入的命令创建别名。我个人的克星是`switch`，但我刚刚决定始终使用上面建议的短“`sw`”，而不是为我在该单词中可能出现的所有可能的拼写错误创建别名。但这里有一些灵感的例子：

```
[alias]
    comit = commit
    swicht = switch
    statut = status
```

现在，您可能已经在考虑哪些 Git 命令最适合使用别名。几年前我想出了一个有趣的答案。就像 Git 一样，我的 shell（Bash、Zsh）也支持别名。因此，我在`.bashrc`和`.zshrc`配置文件中创建了以下 shell 别名：

`alias frequentgit='history | cut -c 8- | grep git | sort | uniq -c  | sort -n -r | head -n 10'`（注意：这是 shell 别名，而不是 Git 别名）。

 

如果我在任何时间点运行此别名，它都会查看我的 shell 历史记录并列出最常用的 Git 命令。

![image-20240625091440202](https://assets.czyt.tech/img/image-20240625091440202.png)

其中一些可能已经是现有别名（此处为 slog、st 和 glog），但其他别名很可能是您“缩短”或记住使用已经创建的别名的良好候选者。尽管我有“`git st`”别名，但我如此频繁地使用“`git status`”的唯一原因是我提供了大量的 Git 培训课程，在这些课程中我致力于使用实际的命令。

### 第 2 级：简单选项，避免输入每日选项标志

因此，是时候在 Git 别名音量控制上提升一个档次了。别名还允许我们向我们要别名的 Git 命令添加“选项”，所以让我们看看如何利用它。

最常见的用例是为 Git 日志输出的常见变体创建简单的别名。

 例如。：

```
[alias]
    last  = log -1
    lo = log --oneline
    l5 = log --oneline -5
```

另一个很好的建议是使用此功能来创建那些令人讨厌的“缺失”Git 命令，您认为这些命令应该存在，并且您可能很难记住必须使用哪个确切命令和选项来完成该非常常见的任务。

`mend = commit --amend
untrack = rm --cached
unadd = restore --staged`请记住，别名是个人喜好。您必须为您可能实际使用（和理解）的命令创建对您有意义的别名。此类别中更高级的示例可能是：

```
pleasepush = push --force-with-lease
gg = grep -E --line-number
softadd = add --intent-to-add
catp = cat-file -p
```

不可否认，许多 Git 用户可能从未听说过这些 Git 命令和选项，更不用说使用它们了。这使得这些别名要么毫无用处，要么成为一个很好的学习机会。

### 第三级：复杂的参数帮助我们记住很少使用的命令

我们旅程的下一个层次是研究对也采用复杂参数的命令使用别名。

```
[alias]
foo = <subcommand> <option> <arg...> <option> <arg...>    
```

到目前为止，我们主要关注频繁或常用命令的别名，但由于我们现在可以缩短更复杂的命令，因此我们可能还会发现朝另一个方向使用别名很有用：

- 不常用且难以记住的 Git 任务。
- 使难以输入的命令变得更加方便。

总之，这允许您使用您可能不会费心的 Git 功能。

```
# Diff of last commit
dlc = diff --cached HEAD^ 

# list all defined aliases
aliases = config --get-regexp alias

# Find very first commit
first = rev-list --max-parents=0 HEAD

# what would be merged
incoming = log HEAD..@{upstream}

# what would be pushed
outgoing = log @{upstream}..HEAD
outgoing = log @{u}..

# List all commits (on this branch) made by me
mycommits = log --author=\".*[Jj]an\\s*[Kk]rag.*\"
```

正如您所看到的，我在上面的示例中通过使用在配置文件中添加 # 注释的功能描述了“内联”别名。这不仅是为了使示例更容易，而且强烈建议您在实际配置中也这样做。我花了很多年的时间才学会了执行此操作的艰难方法，现在我收集了许多奇怪的别名和其他设置，但我不太记得它们的用途。

让我们看一下我收集的一些更具体且常用的示例。这次我将实际向大家展示结果。我将向您展示一个有用的 diff 别名，但首先是在 markdown 文件上运行`git diff`的“之前”视图。

![img](https://assets.czyt.tech/img/Git%2520diff.png)

现在让我们添加一个别名：

```
wdiff = diff -w --word-diff=color --ignore-space-at-eol
```

并使用它来代替：

![img](https://assets.czyt.tech/img/Git%2520wdiff.png)

这显然更加清晰并且更容易掌握。发挥魔力的并不是别名本身，而是别名本身。这些是 Git 中的内置功能。但别名使它在我的日常生活中很有用，因为我懒得每次都记住输入：`git diff -w --word-diff=color --ignore-space-at-eol`。

 让我们定义：

```
[alias]
structure = log --oneline --simplify-by-decoration --graph --all
```

然后在一个巨大的存储库上运行命令：
`$ git structure`

![img](https://assets.czyt.tech/img/Git_stucture-001.png)

显示的代码片段仅显示“带标签”（标签或分支头）的提交，涵盖了 Tensorflow 存储库中 3,000 多个提交。

为了结束这个级别，并很好地进入下一个级别，让我们看看使用具有复杂参数的别名最有益的用途是什么：能够创建更多定制的`git log`命令，以满足您的喜好，通过利用自定义格式。我不希望这成为有关实际格式选项的教程，所以让我们直接深入，您就会明白其中的要点。这一切都在`git help log`的漂亮格式部分中有详细记录。

我向您介绍我的日常司机：

```
slog = log --pretty=format:'%C(auto)%h %C(red)%as %C(blue)%aN%C(auto)%d%C(green) %s'
```

![img](https://assets.czyt.tech/img/Git%2520slog.png)

### 第 4 级：漂亮的格式 - 通过可重用性清理别名

对于这个级别，让我们冒险超越 Git 别名的直接领域，我将教您如何使用自定义漂亮格式的鲜为人知的功能来清理别名并极大地提高可重用性。

我们在上面看到了如何利用自定义格式字段来精确制作我喜欢的日志输出，这一切都很好，直到您意识到我曾经拥有以下所有内容：
```
slog = log --pretty=format:'%C(auto)%h %C(red)%as %C(blue).....
#(For those lazy days).
l = log --pretty=format:'%C(auto)%h %C(red)%as %C(blue).....
l1 = log -1 --pretty=format:'%C(auto)%h %C(red)%as %C(blue).....
l5 = log -5 --pretty=format:'%C(auto)%h %C(red)%as %C(blue).....
l10 = log -10 --pretty=format:'%C(auto)%h %C(red)%as %C(blue).....
l20 = log -20 --pretty=format:'%C(auto)%h %C(red)%as %C(blue).....
```

（实际别名要长得多，但格式字符串相同）。

还有很多类似的。每次我想调整格式或颜色等时，这都变得非常烦人。

如今，在最新版本的 Git 中，别名可以引用其他别名，因此可以大大改进上述内容，例如：

```
l1 = slog -1l5 = slog -5
```

但事实证明还有更好的选择。

您可能知道 Git 有一些内置的“漂亮”格式，您可以在日志中使用它们，例如：
```
git log --pretty=oneline
git log --pretty=full
git log --pretty=raw
```

（有关更多内容，请参阅上面链接的文档）。

在我的旅程中为时已晚，我发现 Git 允许我在 Git 配置中定义自己的自定义“漂亮”格式，但是当我发现这个功能时，它太棒了！

这些格式可以在配置的`[pretty]`部分（或`git config –global pretty.myformat …..`）中定义，如下所示：

```
[pretty]
    slog = format:%C(yellow)%h %Cred%as %Cblue%an%Cgreen%d %Creset%s
    bw = format:%h | %as | %>(20,trunc)%d%x09%s
```

一旦定义了这些，我就可以在运行 Git log 命令时随时使用它们：

```
$ git log --pretty=slog
```

这也意味着我可以重写所有奇怪的日志别名以使用我自己的漂亮格式，然后每当我的品味发生变化时我就有一个可以编辑的地方。

```
[alias]
    l1 = log -1 --pretty=slog
    l5 = log -5 --pretty=slog 
    slog = log --pretty=slog
    slogbw = log --pretty=bw
    glog = log --graph --pretty=slog 
    outgoing = log --pretty=slog @{u}..
```

定义这些漂亮格式的另一个好处是，即使在运行“即时”日志命令时，我也可以“按需”使用它们。

```
$ git log --pretty=slog --no-merges --author-date-order  foo..bar
```

### 级别 5：前缀 - 覆盖特定 Git 子命令的 Git 行为

对于第 5 级，为了完善这篇“第 1 部分”博客文章，我们将使用一个相当未知的功能来了解 Git 别名中的一个非常未知的功能。

事实证明，Git 别名不仅可以将选项发送到 Git 子命令，还可以发送到`git`命令本身。如果您在想，“我不知道 Git 命令有选项”，那么您可能并不孤单。

一个有用且易于解释的示例是控制分页的选项。默认情况下，Git 会将任何超过一屏的输出传递给 less（或其他配置的分页器），并且小于一屏的输出将被直接打印。但是 Git 允许我们根据需要覆盖此行为，例如：

```
git –paginate git --no-pager 
```

让我们看看如何在别名中使用它。
 例如。：

```
pst = --paginate status # so that output doesn't stick around on your screen and scroll buffer when you quit less
listconfig = --no-pager config --list # so that output stays on your screen and scroll buffer to allow copy/paste
```

此功能的另一个很好的用途是将其与 Git 临时覆盖配置设置的功能结合使用。

在 Git 中，您可以使用`-c`选项仅覆盖此单个命令的配置值，`i.e., git -c <config override> <subcommand>.`

这也可以用作别名：

```
annoncommit = -c user.name="Anonymous" -c user.email="notme@localhost" commit
```

注意：这与使用`git commit --author=`不同，因为它同时设置作者和提交者身份，如以下示例所示：

```
$ git add .
$ git annoncommit --message 'foo'
$ git log --pretty=full
commit 0ae65ffc6192b6a2561db906bfed5c45bac702db (HEAD -> master)
Author: Anonymous 
Commit: Anonymous 

    foo
```

让我们看一些更有用的例子：

```
# Verbose commit (add diff to comments in commit text)
vcommit = -c commit.verbose=true commit
# Use VSCode for editing, just this once
vscommit = -c core.editor="code --wait" commit
# Use VSCode for interactive rebase
riv = -c sequence.editor="code --wait" rebase -i
```

## Git 博客文章系列的下一篇内容是什么？

我向您介绍的不仅仅是 Git 别名的基础知识。我们已经看到它们如何对日常工作、我们经常使用的命令或我们很少使用以至于我们记不住的命令非常有帮助。我们还尝试了 Git 本身的选项（这已经是大多数用户不知道的功能），从而稍微超出了普通 Git 别名的范围。

这是一个让您对第二部分充满期待的好地方，我们将继续：

1. !non-git 命令：更“划算”。
2.  重用别名。
3. 流水线操作：链接 Unix 工具以实现更多操作或疯狂。
4. Bash 的功能是为了胜利。
5. 太过分了，因为只有跨越界限才能找到界限。
6. 探索 Git 别名的替代品的奖励回合。

第 2 部分见！

# 第二部分：高级到卓越

> https://www.eficode.com/blog/10-levels-of-git-aliases-advanced-and-beyond

在我的两部分博客文章的第一部分中，我带您从非常简单的基础知识开始，介绍了 Git 别名，展示了它们如何替换又长又复杂的命令，甚至还介绍了一些大多数用户不知道的概念，例如将参数发送到 Git 本身的别名以及使用自定义漂亮格式的高级日志格式。

在继续之前，我强烈建议您先阅读第一部分。

在第二部分中，我介绍了更高级的概念，并尝试真正“外面”使用 Git 别名，包括一些彻头彻尾疯狂的示例。最后，我将介绍一些解决相同需求的替代方案。

那么，让我们深入了解一下。

## 6级：！非 Git 命令

更划算。

Git 别名允许我们扩展我们在 Git 上下文中可以做的事情的词汇量。本节以及接下来的大部分内容，探讨了当我们走出 Git 子命令的界限时我们能够做什么。

“bang”功能改变了 Git 别名的功能，因为它允许我们调用 shell 并在系统上运行任何 shell 命令。我们只需在别名扩展前面加上感叹号（或 Unix/shell 世界中的“bang”）即可完成此操作。

让我们从一个非常简单的例子开始，它清楚地演示了这个概念并且实际上很有用。

在某些平台上，Git 预装了两个有用的 GUI 工具，“Git gui”用于暂存和提交，“Gitk”用于查看历史记录。但为什么`git gui`是 Git 子命令，而`gitk`不是呢？相当混乱，但可以使用别名轻松修复：

 

```
[alias]  # Make git k call gitk  k = !gitk
```

当我们这样做时，我也遇到了类似的问题。当我的大脑深入“Git”模式时，在我决定使用哪个命令之前，我的手指经常会输入“Git”。然后突然，我决定需要列出文件夹中的文件并快速输入`ll <enter>`（我的日常 shell 别名为`ls -al`），突然我得到：

`$ git llgit: 'll' is not a git command. See 'git --help'.`这应该可以通过适当的别名来解决：

```
[alias]  # This should make git ll work like ll  ll = !ls -al
```

现在，“拼写错误”`git ll`可以正常工作，但会导致发现有关 bang 功能的一个非常重要的警告，如图所示，这既是福也是祸。

感叹号从 Git 存储库的根文件夹启动 shell 上下文！



因此，虽然我的`git ll`别名似乎有效，但它始终会向我显示存储库根文件夹的内容，即使我位于子文件夹中也是如此。

为了说明此功能的用途，让我们尝试一下别名：

```
[alias]  rootpath = !pwd
```

shell命令pwd打印当前工作目录；这个别名提供了一个快速的快捷方式来打印我的存储库所在的路径。

诚然，这个特定问题可以通过普通的 Git 别名得到更好的解决，从而避免创建新的 shell 会话（不过，哪个运行速度更快还没有定论）。

```
[alias]  rootpath = rev-parse --show-toplevel  
```

但我至少有一个很好的利用这一副作用的方法。有时，当您由于其他原因`cd`深入到子文件夹时，读取 Git 状态输出真的很烦人，因为所有其他路径都是相对于当前文件夹打印的，因此您会看到提到的更改喜欢：

```
new file:  ../../../../foo 
```

因此，让我们利用“根文件夹”副作用并添加常规 st 别名的替代方案：

```
[alias] st = status rootstatus = !git status sr = !git status
```

这将始终显示相对于存储库根的状态输出。

![img](https://assets.czyt.tech/img/Git-1.png)

（-s 仅适用于不太详细的“短”格式输出）。

请注意，使用配置变量 status.relativePaths 和本博文第一部分“级别 5”中讨论的 -c 功能可以实现类似的效果。

为了结束本节，让我们来玩点乐子。如果我无意识地在 ll 之前键入 Git，有时我也会在决定查找（例如 Git 状态）之前键入 Git，从而导致不幸的情况：

`$ git git statusgit: 'git' is not a git command.`所以，我的大脑想出了创建的想法：

```
[alias]  git = !git
```

是的，这使得`git git status`可以工作，并且由于别名的递归性质，甚至`git git git git git status`现在也可以工作......在纸上。

事实上，这与其说是一个好主意，不如说是一个好笑话，因为它带来了两个主要后果。第一个问题，如上所示，是该命令现在将从根存储库文件夹运行，这可能会导致混乱。第二个问题是它破坏了运行 git help`git to get`的相当重要的功能，即实际 Git 命令的帮助页面。现在，它会打印出不太有用的内容：

```
'git' is aliased to '!git' 
```

## 第 7 级：重用 Git 别名

建立在之前的基础上
……使用之前的内容

在旧版本的 Git 中，2.20 之前，Git 别名不允许引用其他 Git 别名。这通常会导致配置文件中出现许多类似的别名，正如我们在讨论自定义 Git 日志命令时所看到的那样。

唯一可用的解决方法是利用 bang 功能，因为事实证明它是完全可行的：

```
[alias] l1 = !git slog -1  l5 = !git slog -5
```

这不是递归调用现有别名，而是启动一个新的 shell 会话，该会话恰好使用带有别名的 Git。

幸运的是，自 Git 2.20 (2018) 起，递归别名已被允许，自 2.30 (Q1 2021) 起，甚至 bash-completion (tab-completion) 也能理解和翻译。

因此，为了获得更清晰的 Git 配置，我现在可以：

`[alias] slog = log --pretty=format:'%C(auto)%h %C(red)%as %C(blue)%aN%C(auto)%d%C(green) %s' l = slog l1 = l -1  l5 = l -5`我经常使用它来提高配置的可读性。当我添加一个新的花哨别名时，我会给它一个很好的描述性名称，然后在下面添加一个简短的形式供日常使用。例如，在上一篇文章中，我展示了“传入”和“传出”更改的简短日常使用版本：

```
[alias]  in = incoming   out = outgoing
```

## 第 8 级：流水线操作

链接 Unix 命令以获得更多控制（或疯狂）

我之前提到过“爆炸”功能是一个游戏规则改变者，但我们只触及了表面。当您意识到调用 shell 可以将多个命令链接在一起时，下一步就到来了。

最简单的用法是别名，使用 shell 和运算符`&&`依次执行多个单独的操作。

`[alias] # init new git repo with empty initial commit start =  !git init && git commit --allow-empty -m \"Initial commit\" # create a git repo including everything in this dir initthis =  !git init && git add . && git commit -m \"Bootstrap commit\"`我们可以通过使用 shell 命令替换功能更进一步，该功能允许在另一个命令中内联使用命令的输出。让我们看一些例子来证明这一点：

```
[alias] # Alternative version of the mycommits alias from level 3  # Better/worse?: It is less hardcoded but only finds commits # matching current config. lome = "!git slog --author=$(git config --get user.name)" # Switch to master/main/trunk or whatever is the default branch is # in this repo swm = !git switch $(basename $(git symbolic-ref --short       refs/remotes/origin/HEAD))
```

注意：为了可读性，上面的别名被包装起来。它需要位于配置中的一行上。稍后会详细讨论这个问题。

我们甚至可以使用现有的环境变量或在别名中内联定义新的环境变量。

几年前，我在客户办公室的墙上看到了这个“模因”：

![img](https://assets.czyt.tech/img/In%2520case%2520of%2520fire.png)

我为我们自己的办公室打印了一份副本，这在 Slack 上引发了一场漫长而幽默的讨论，讨论为什么这不起作用以及它需要改进的所有方法。

最终结果是以下别名的 gem，很好地演示了变量的使用：

```
[alias] panic = !PD=$(date +%d%m%y-%H%M)  && git add -A  && git commit -mWAAAAAAAAGH!!   && git switch -C PANIC-$USER-$PD  && git push -f origin PANIC-$USER-$PD
```

但当我们更进一步并开始使用 Unix 管道将输出从一个命令传递到另一个命令时，真正的力量就出现了。

首先，我定义一个快速`remoteurl`别名，以便更轻松地获取 Git 远程的 URL。但是，如果我使用 ssh 克隆存储库，并且当我想使用它来查找存储库的网站时有一个“git@”格式的 URL，该怎么办？

让我们将第一个命令的输出发送到 sed，它会搜索/替换并与`https://`交换`git@`。

为了解决这个问题，让我们添加一个别名，使用 Mac`pbcopy`命令将输出直接结束到我的剪贴板。 （在 Windows 上，我们可以对`clip`执行相同的操作）。

```
[alias] remoteurl = "remote get-url origin" remotehttps = "!git remoteurl | sed  -e 's/git@/https:\\/\\//'" remotecopy  = "!git remotehttps | pbcopy" 
```

同样，我们可以使用其他 shell 功能，例如将输出重定向到文件。我有时发现自己想在我的存储库中创建一个 .mailmap 文件。例如，这使您可以将某些贡献者的旧电子邮件“映射”到新电子邮件，或确保用户的不同拼写得到组合。

为了为邮件地图提供一个良好的起点，我需要一个作者列表，其姓名和电子邮件采用标准“Jan Krag ”格式，有点类似于我从`git shortlog -sne`，但没有第一列数字。

为了解决这个问题，我想出了以下别名：

```
[alias] mm  = "!git log  --format='%aN ' | sort -u" mmm = "!git mm >> .mailmap" mmme = "!git mmm && code .mailmap"
```

日志只是打印出每次提交的作者和电子邮件，然后使用 shell`sort`命令上的“唯一”开关来删除重复项并对输出进行排序。第一个别名将它们打印到控制台，而第二个别名则重定向输出并创建或附加到现有的 .mailmap 文件。

第三个是“我很着急”的便捷版本，它可以立即在我的 VSCode 编辑器中打开新的 .mailmap 文件。因此，我们在这里将管道、重定向和 && 功能组合到一个别名中。

##  第 9 级：函数

Bash 函数是为了胜利！

让我们再次提升我们能做的事情。现在我们有了这个 shell 上下文，我们可以使用的另一个功能是定义函数的能力。你可能会问，我为什么要这么做？在某种程度上，它确实使复杂的别名变得更清晰，但最重要的方面是能够读取命令行参数并以更受控制的方式使用它们。

在普通别名中，您可以选择在别名后面附加任何您想要的开关和参数，这些是在扩展之后添加的。例如，回到上一篇文章中的 Git slog 别名，将其用作 git`slog -3`或`git slog --all.`是完全可以的，但是如果我想在其中创建一个别名，该怎么办？需要在多个地方进行一些争论吗？

一个非常简单的例子是我用于删除本地和远程分支的别名：

```
[alias] rmbranch =  "!f(){ git branch -d ${1} && git push origin --delete ${1}; }; f"
```

注意语法。在我的 shell 上下文中，我首先定义一个函数`f()`，它执行从开头 { 到最后 }; 的语句。

最后，我只是通过函数名称`f`来调用该函数。好处是我们现在可以将参数传递给函数，并且这些参数在函数作用域中作为“位置参数”提供，从 1 开始编号。因此`${1}`只是引用用户在调用函数时提供的第一个参数，正如您在示例中看到的，我们可以根据需要多次使用参数。

让我们看另一个简单的例子：

```
[alias] # Easy add a GitHub repo as new remote  ghremote = "!f(){ git remote add $1 https://github.com/$2.git; }; f"
```

在此示例中，我使用的函数不是为了重用参数，而是因为我想采用多个参数并在别名中内联的非常特定的位置使用它们。

您可能会注意到，此示例使用不带花括号的位置参数。这只是为了说明，根据 bash 标准，只有超过 9 个的位置参数才需要大括号，因此这取决于您的偏好。

让我们试试这个`ghremote`别名：

```
$ git ghremote jan jkrag/git-katas$ git remote get-url janhttps://github.com/jkrag/git-katas.git$ git fetch janremote: Enumerating objects: 6, done.
```

## 第10级：太过分了

引入多行格式。

我们之前见过一些别名的示例，这些别名最终会在您的配置中出现很长的行，因此接近“不可读”。然而，有一种方法可以真正拥有真正的多行别名。只需在末尾添加一个反斜杠即可转义换行符。

然而，这并没有真正回答“我应该吗？”这个问题。

在某些时候，我们达到了在别名中实际理智的做法的极限，您应该考虑我将在“第 11 级”中介绍的一些替代选项。但是，毕竟这是一篇关于别名的博客文章，所以让我们稍微突破一下界限，您可以做出自己的判断。

让我们以一个相当复杂但有时有用的示例开始本节，我不会详细解释该示例。

```
[alias] # Delete all branches merged into master.  # With -f also include branches merged into current sweep = ! \    git branch --merged $( \    [ $1 != \"-f\" ] \\\n \      && git rev-parse master \    ) \    | egrep -v \"(^\\*|^\\s*(master|develop)$)\" \\\n \    | xargs git branch -d
```

亲爱的读者，将其与`swm`别名中的符号引用技巧相结合来查找默认分支作为练习。

没有太多需要解释的了，所以让我们看几个可以激发您尝试编写自己的别名的示例。

### “我只想打开这个仓库的网站。”

但是如果 Git 远程使用 ssh 该怎么办？

`[alias] # Open repo in browser  browse = "!f() { \     open `git remote -v \     | awk '/fetch/{print $2}' \     | sed -Ee 's#(git@|git://)#http://#' -e 's@com:@com/@'` \     | head -n1; \   }; f"`为什么 git diff 不包含新文件？

```
[alias] udiff =   "!f() { \      for next in \        $(git ls-files --others --exclude-standard); \      do \        git --no-pager diff --no-index /dev/null $next; \        done;   }; f"
```

让我们看看它的使用情况：

![img](https://assets.czyt.tech/img/git-2323231.png)

#### 哪些文件最受欢迎？

我最初在 Michael Wales 的一篇 .gitconfig 博客文章中找到了这个，并根据我的喜好对其进行了稍微修改。

```
[alias] churn = !git -p log --all -M -C --name-only \   --format='format:' $@ \    | sort \    | grep -v '^$' \    | uniq -c \    | sort -r \    | awk 'BEGIN {print count,file} {print $1 , $2}'
```

并在 git-katas 存储库上使用：

```
$ git churn42 README.md24 basic-commits/README.md21 basic-branching/README.md19 ignore/README.md19 basic-staging/README.md17 submodules/README.md17 3-way-merge/README.md16 configure-git/README.md15 Overview.md14 ff-merge/README.md
```

#### 为什么我需要知道如何继续？

我经常提供 Git 培训，每次我们谈论解决合并/变基冲突时，我都会很高兴地介绍：

```
git merge --continuegit rebase --continuegit cherry-pick --continuegit revert --continue
```

在某些时候，我开始想，“为什么，哦为什么，当 Git 显然知道它处于合并状态、变基状态等时，作为用户，我需要指定我要继续的‘什么’吗？为什么没有一个`continue`命令来‘做正确的事？’”

我记得，我做了我们在 ChatGPT 之前所做的事情，并在网络上搜索并找到了一个可以执行此操作的 bash 脚本。正如下一章中提到的，这可能也是明智的解决方案，但作为粉丝，我做了必须做的事情并使其作为纯别名工作。因此，我可以给你们带来这个真正包含了过分精神的怪物：

```
[alias] # merge --continue, rebase --continue  # whatever --continue continue = "!f() { \    repo_path=$(git rev-parse --git-dir) && \    [ -d \"${repo_path}/rebase-merge\" ] && git rebase --continue && return; \    [ -d \"${repo_path}/rebase-apply\" ] && git rebase --continue && return; \    [ -f \"${repo_path}/MERGE_HEAD\" ] && git merge --continue && return; \    [ -f \"${repo_path}/CHERRY_PICK_HEAD\" ] && git cherry-pick --continue && return; \    [ -f \"${repo_path}/REVERT_HEAD\" ] && git revert --continue && return; \    echo \"Nothing to continue?\"; \  }; f"
```

###  共享 Git 别名

作为本节的结束语，我将与大家分享我大约 10 年前通过努力和决心开发的“圣杯”别名。

例如，我想要解决的问题是在 Slack 上与同事共享别名。如果我想为经验不足的 Git 用户提供快速别名，那么每次都必须解释如何查找和编辑全局配置文件以及将别名代码放在文件中的位置等，这太复杂了。

只需发送适当的 git config –global alias.foo“do this Git thing”命令，他们就可以直接运行，这样会更干净。对于简单的别名，我只是从内存中把它敲出来，但是对于涉及引号和变量的稍微复杂的别名，要正确使用它也不是一件容易的事，所以我想出了一个想法来写一个“`exportalias`“别名。我几乎不知道要把这个做好有多难，一路走来，成功的标准之一就是它应该能够自我出口。我还没有用所有真正疯狂的多行别名对它进行战斗测试，但对于那些，我总是会分享 .gitconfig 片段。

```
[alias] exportalias = "!f() { in=${1}; out=$(git config --get alias.$in) ;   printf 'git config --global alias.%s %q\n' $in \"$out\";};f"
```

我故意没有换行，以确保它是可导出的形式。

让我们在本文前面的一个不平凡的别名上尝试一下——它不仅包含特殊字符，还包含转义引号。

```
$ git exportalias startgit config --global alias.start \!git\ init\ \&\&\ git\ commit\ --allow-empty\ -m\ \"Initial\ commit\"
```

## 第 11 级：奖金轮

疯狂有极限吗？

在最后的奖励部分中，我将向您介绍一些扩展 Git 功能的替代方法 - 这些选项可能比全页多行别名更明智。

###  自定义可执行文件

首先是认识到 Git 的构建是明智的，因此路径中名为`git-something`的任何可执行文件都将变成`git something`命令。

这意味着我们的一些较长的别名可以作为简单的 bash 脚本来实现。您可能会问，为什么这很重要？部分原因是您避免了留在 .gitconfig 文件范围内的许多格式化麻烦，例如必须转义换行符和混乱不必要的引用。

另一个优点是我们可以通过正确的参数解析、错误处理、使用帮助文本等更好地编写“真实”脚本。

```
#!/usr/bin/env bashusage() {cat <<HEREusage: git alias             # list all aliases  or: git alias     # show aliases matching pattern  or: git alias   # alias a commandHERE}case $# in 0) git config --get-regexp 'alias.*' | sed 's/^alias\.//' | sed 's/[ ]/ = /' | sort ;; 1) git alias | grep -e "$1" ;; 2) git config --global alias."$1" "$2" ;; *) >&2 echo "error: too many arguments." && usage && exit 1 ;;esac
```

实际上，Git 甚至不需要您使用 Bash。您可以用任何语言编写新的 Git 命令，尽管您可能希望坚持使用具有良好 Git 库的语言，可能是 Python、Java 或 Go-lang。

###  Git 扩展包

如果我们可以在路径中将自定义 Git 命令编写为二进制文件，那么我们还可以编写和分发它们的整个集合。甚至有开源项目提供此类“Git 扩展”，要么用于特定目的，要么只是“有用”命令的一般集合。

这些通用集合中最大的一个是 https://github.com/tj/git-extras，安装后会向您的组合添加 70 多个新命令，包括自服务的`git extras`，其中列出了所有这些。它可以与大多数常见的包管理器一起安装，或者手动克隆（如果这不是一个选项），例如：`$ sudo apt-get install git-extras`

or

```
$ brew install git-extras
```

我不会列出所有 70 个命令，但以下是一些选定的提及：

- git-abort：中止当前的 Git 操作。
- git-alias：定义、搜索和显示别名。
- git-magic：自动化添加/提交/推送例程。
- git-repl：Git 读取评估打印循环。
- git-standup：回想一下你在上一个工作日做了什么。

另一个可能值得关注的扩展包是 Git Pastiche，它包含的命令选择要少得多，可能级别更低一些，但我发现特别是`git stats`和`git activity`相当有时有用。

在这种情况下，可能还值得一提的是，我们认为是 Git 的“核心”扩展的东西，例如`Git LFS`，又名 Git 大文件存储，也是使用此概念构建的扩展，并用 Go 编写-郎。核心 Git lfs 命令只是一个 git-lfs 可执行文件，它负责将所有 lfs 子命令重定向到其他 Go 程序。

####  帮助

在结束语中，我将非常简短地介绍帮助。如果您确实想全力以赴地使用自定义 Git 命令，就像“git extras”和其他命令所做的那样，您可以提供自定义帮助页面。

输入`git help mycustom`确实会让 Git 检查你的系统上是否有 mycustom 的手册页。介绍如何创建手册页超出了本博客文章的范围，但很容易找到涵盖它的优质资源。

对于 Git 别名，您可能已经注意到类似`git help st`的内容只是打印出来：

```
'st' is aliased to 'status'
```

这可能有用也可能没用，具体取决于您的需要。

对于像这样的基本别名，即不使用 bash 的别名，您还可以使用格式`git st --help`来显示 aliases 命令的正常帮助页面，在本例中为`git status`。

####  致谢和免责声明

这篇文章中的示例来自我十多年来使用 Git 的个人收藏。有些已针对我在每个部分中尝试演示的内容进行了修改。

至于这些别名的来源，有些是我自己写的，有些是同事、Git 课程的参与者和朋友传给我的。有些是我多年来在网上找到的，然后按原样复制或改编以供我自己使用。总的来说，有一种分享这些东西的社区精神，所以我希望这属于“合理使用”。

最近，我开始在我的配置中为非常复杂的别名添加注释，说明我在哪里找到它们，但即便如此，也很难追踪这些代码示例的起源，因为其他人与我做同样的事情（从某处借用并根据需要进行调整） ）。

如果您在这篇博文中发现了您认为自己是原作者的别名，请告诉我，我将引用您的别名或根据要求将其删除。

> 作者的GitHub仓库地址  https://github.com/tj/git-extras
