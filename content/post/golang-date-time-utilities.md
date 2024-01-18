---
title: "Golang 高级时间工具函数"
date: 2024-01-18
tags: ["golang"]
draft: false
---

>本文为 https://medium.com/canopas/golang-date-time-utilities-part-2-b1192eb04842 文章的翻译。正文部分进行了部分调整。

# 背景介绍

在编程世界中，处理日期和时间是一项常见的任务，通常需要精确性和灵活性。

虽然 Go 编程语言的标准库提供了 `time` 软件包来处理与时间相关的操作，但在某些情况下，开发人员需要额外的实用程序来简化与时间相关的任务。

在本篇博文中，我们将探讨一组实用工具函数，它们是 `time` 程序包的封装，可为操作提供便利。如果您不了解 [time](https://pkg.go.dev/time)程序包，请考虑在深入学习高级实用程序之前参考一下相关文档。

有关基本功能，请参阅您始终需要的时间实用功能。

🎯 那么，让我们深入探讨一下如何实现。

# 实现

## 1.获取月初

一个月的开始是许多日期相关计算的基本参考点。让我们创建一个函数，将日期作为输入，并根据系统时区返回相应月份的第一天：

```go
func StartOfMonth(date time.Time) time.Time {
    return time.Date(date.Year(), date.Month(), 1, 0, 0, 0, 0, date.Location())
}

// function called
StartOfMonth(time.Now())

// output
2024-01-01 00:00:00 +0530 IST
```

此函数将月日设置为 1，其他部分保持不变。

## 2.获取月末数据

相反，获取月末也同样重要。下面的函数返回给定月份最后一天的最后一秒：

```go
func EndOfMonth(date time.Time) time.Time {
    firstDayOfNextMonth := StartOfMonth(date).AddDate(0, 1, 0)
    return firstDayOfNextMonth.Add(-time.Second)
}

// function called
EndOfMonth(time.Now())

// output
2024-01-31 23:59:59 +0530 IST
```

该函数利用之前定义的 `StartOfMonth` 函数查找下个月的第一天，然后减去一秒，得到当前月份的月底。

## 3.获取每周的开始日

对于创建日历或显示每周数据等任务，了解每周的起始日很有帮助。下面的函数提供了给定日期一周的第一天：

```go
func StartOfDayOfWeek(date time.Time) time.Time {
    daysSinceSunday := int(date.Weekday())
    return date.AddDate(0, 0, -daysSinceSunday)
}

// function called
StartOfDayOfWeek(time.Now()) // time.Now() = 2024-01-16 16:00:12.901778919 +0530 IST

// output
2024-01-14 11:31:37.344224696 +0530 IST
```

此函数计算从星期日开始的天数，并从给定日期中减去此值。

## 4.获取每周的最后一天

同样，获取一周的最后一天也是经常需要的。下面的函数可以实现这一功能：

```go
func EndOfDayOfWeek(date time.Time) time.Time {
    daysUntilSaturday := 6 - int(date.Weekday())
    return date.AddDate(0, 0, daysUntilSaturday)
}

// function called
EndOfDayOfWeek(time.Now()) // time.Now() = 2024-01-16 16:00:12.901778919 +0530 IST

// output
2024-01-20 11:31:37.344227536 +0530 IST
```

此函数计算距离周六的天数，并将此值与给定日期相加。

## 5.获取指定月份每周的开始和结束日期

要全面了解一个月中每周的情况，我们可以将前两个函数结合起来。下面的函数会返回一个片段，其中包含给定月份中每周的开始和结束日期：

```go
func StartAndEndOfWeeksOfMonth(year, month int) []struct{ Start, End time.Time } {
   
    startOfMonth := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC)
    weeks := make([]struct{ Start, End time.Time }, 0)
    
    for current := startOfMonth; current.Month() == time.Month(month); current = current.AddDate(0, 0, 7) {
        startOfWeek := StartOfDayOfWeek(current)
        endOfWeek := EndOfDayOfWeek(current)

        if endOfWeek.Month() != time.Month(month) {
            endOfWeek = EndOfMonth(current)
        }
        weeks = append(weeks, struct{ Start, End time.Time }{startOfWeek, endOfWeek})
    }

    return weeks
}

// function called
StartAndEndOfWeeksOfMonth(2024, 1)

// output
[{2023-12-31 00:00:00 +0530 IST 2024-01-06 00:00:00 +0530 IST}
 {2024-01-07 00:00:00 +0530 IST 2024-01-13 00:00:00 +0530 IST}
 {2024-01-14 00:00:00 +0530 IST 2024-01-20 00:00:00 +0530 IST}
 {2024-01-21 00:00:00 +0530 IST 2024-01-27 00:00:00 +0530 IST}
 {2024-01-28 00:00:00 +0530 IST 2024-01-31 23:59:59 +0530 IST}]
```

该函数遍历给定月份的每个星期，确定每个星期的开始和结束日期。

## 6.从日期获取月份的周数

最后，通过以下函数可以确定从特定日期开始的月份的周数：

```go
func WeekNumberInMonth(date time.Time) int {
    startOfMonth := StartOfMonth(date)
    _, week := date.ISOWeek()
    _, startWeek := startOfMonth.ISOWeek()
    return week - startWeek + 1
}

// function called
WeekNumberInMonth(time.Now()) // time.Now() = 2024-01-16 16:00:12.901778919 +0530 IST

// output
3
```

该函数计算给定日期的 ISO 周数，然后减去该月第一天的 ISO 周数，再加 1 得到该月的相对周数。

## 7.获取新年伊始

要检索给定日期的年初一时刻，我们可以创建一个如下函数：

```go
func StartOfYear(date time.Time) time.Time {
    return time.Date(date.Year(), time.January, 1, 0, 0, 0, 0, date.Location())
}

// function called
StartOfYear(time.Now())

// output
2024-01-01 00:00:00 +0530 IST
```

该函数将月份设置为 1 月，将日期设置为 1，从而提供了一年的开始时间。

## 8.获取年终报告

同样，我们也可以定义一个函数来获取一年中最后一天的最后一秒：

```go
func EndOfYear(date time.Time) time.Time {
    startOfNextYear := StartOfYear(date).AddDate(1, 0, 0)
    return startOfNextYear.Add(-time.Second)
}

// function called
EndOfYear(time.Now())

// output
2024-12-31 23:59:59 +0530 IST
```

该函数利用 `StartOfYear` 函数找到下一年的第一天，然后减去一秒，得到当年的年底。

## 9.获取季度开始时间

对于需要季度数据的任务，我们可以创建一个函数来获取给定日期的季度开始时间：

```go
func StartOfQuarter(date time.Time) time.Time {
    // you can directly use 0, 1, 2, 3 quarter
    quarter := (int(date.Month()) - 1) / 3
    startMonth := time.Month(quarter * 3 + 1)
    return time.Date(date.Year(), startMonth, 1, 0, 0, 0, 0, date.Location())
}

// function called
StartOfQuarter(time.Now())

// output
2024-01-01 00:00:00 +0530 IST
```

此函数计算给定日期的季度，并将月份设置为该季度的第一个月。

## 10.获取季度末

为了补充前一个函数，我们可以创建一个函数来查找给定日期的季度末：

```go
func EndOfQuarter(date time.Time) time.Time {
    startOfNextQuarter := StartOfQuarter(date).AddDate(0, 3, 0)
    return startOfNextQuarter.Add(-time.Second)
}

// function called
EndOfQuarter(time.Now())

// output
2024-03-31 23:59:59 +0530 IST
```

该函数利用 `StartOfQuarter` 函数确定下一季度的第一天，然后减去一秒，得到当前季度的结束时间。

## 11.获取当前周范围

获取特定时区当前一周的开始和结束时间非常有用。下面的函数就可以做到这一点：

```go
func CurrentWeekRange(timeZone string) (startOfWeek, endOfWeek time.Time) {
    loc, _ = time.LoadLocation(timeZone)

    now := time.Now().In(loc)
    startOfWeek = StartOfDayOfWeek(now)
    endOfWeek = EndOfDayOfWeek(now)

    return startOfWeek, endOfWeek
}

// function called
start, end := CurrentWeekRange("America/New_York")

// output
2024-01-14 05:47:38.093990643 -0500 EST, 2024-01-20 05:47:38.093990643 -0500 EST
```

该函数使用之前定义的 `StartOfDayOfWeek` 和 `EndOfDayOfWeek` 函数来获取指定时区当前一周的时间范围。除非指定时区，否则它会考虑系统的时区。

## 12.计算两个日期之间的持续时间

计算两个日期之间的持续时间是一项常见任务。该函数返回两个 `time.Time` 实例之间的持续时间

```go
func DurationBetween(start, end time.Time) time.Duration {
    return end.Sub(start)
}

// function called
DurationBetween(time.Now(), time.Now().AddDate(0, 0, 7)) // time.Now() = 2024-01-16 16:00:12.901778919 +0530 IST

// output
168h0m0.000000056s
```

当您需要测量两个事件之间的时间间隔时，这个简单的实用函数会很有帮助。

## 13.获取指定月份的星期日期

此函数将年、月和目标星期作为参数，然后返回一片 `time.Time` 值，代表指定月份中指定日期的所有出现次数。

```go
func GetDatesForDayOfWeek(year, month int, day time.Weekday) []time.Time {
  var dates []time.Time
  
  firstDayOfMonth := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.UTC)
  diff := int(day) - int(firstDayOfMonth.Weekday())
  if diff < 0 {
    diff += 7
  }
  
  firstDay := firstDayOfMonth.AddDate(0, 0, diff)
  for current := firstDay; current.Month() == time.Month(month); current = current.AddDate(0, 0, 7) {
    dates = append(dates, current)
  }
  
  return dates
}

// function called
GetDatesForDayOfWeek(2024, 1, time.Sunday)

// output
[2024-01-07 00:00:00 +0000 UTC 2024-01-14 00:00:00 +0000 UTC 2024-01-21 00:00:00 +0000 UTC 2024-01-28 00:00:00 +0000 UTC]
```

该功能可针对不同月份和星期进行定制，为获取一个月内的特定日期提供了多功能解决方案。

## 14.为日期添加工作日

如果您的应用程序处理工作日，该功能可以方便地将一定数量的工作日添加到给定的日期中：

```go
func AddBusinessDays(startDate time.Time, daysToAdd int) time.Time {
    currentDate := startDate
    for i := 0; i < daysToAdd; {
        currentDate = currentDate.AddDate(0, 0, 1)
        if currentDate.Weekday() != time.Saturday && currentDate.Weekday() != time.Sunday {
            i++
        }
    }
    return currentDate
}

// function called
AddBusinessDays(time.Now(), 50) // time.Now() = 2024-01-16 16:00:12.901778919 +0530 IST

// output
2024-03-26 12:21:55.727849491 +0530 IST
```

该函数会遍历天数，跳过周末，直到达到所需的工作日数。

## 15.将工期格式化为人类可读字符串

在向用户展示工期时，以人类可读的方式格式化工期可以增强用户体验。此函数可将工期转换为用户友好格式的字符串：

```go
func FormatDuration(duration time.Duration) string {
    days := int(duration.Hours() / 24)
    hours := int(duration.Hours()) % 24
    minutes := int(duration.Minutes()) % 60
    seconds := int(duration.Seconds()) % 60
    return fmt.Sprintf("%dd %02dh %02dm %02ds", days, hours, minutes, seconds)
}

// function called
FormatDuration(time.Hour * 24 * 3 + time.Hour * 4 + time.Minute * 15 + time.Second * 30)

// output
3d 04h 15m 30s
```

该功能可将持续时间细分为天、小时、分钟和秒，显示更加方便。

完整源代码请访问 - [Golang: Date Time Utilities](https://github.com/cp-dharti-r/golang-date-time-utils)

今天就到这里。继续编码！👋

#  结论

通过实现这 15 个额外的高级实用功能，我们扩展了日期-时间包封装程序的功能，为开发人员提供了处理各种时间相关操作的综合工具集。

无论您是在构建日程安排应用程序、生成报告，还是在处理任何涉及时间数据的项目，或是在处理日、周、月或季度数据，这些功能都可以无缝集成到您的代码库中，以简化复杂的日期和时间操作。