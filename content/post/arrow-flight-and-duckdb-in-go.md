---
title: "在Go语言中使用Arrow、Flight和Duckdb"
date: 2024-12-05
draft: false
tags: ["golang","duckdb"]
author: "czyt"
---

## 从duckdb开始

DuckDB 是一个嵌入式分析型数据库，专为 OLAP（在线分析处理）工作负载设计。本文将基于 [go-duckdb](https://github.com/marcboeker/go-duckdb) 项目的示例，详细介绍 DuckDB 在 Go 语言中的各种使用场景。

### 基础使用

#### 简单查询
```go
package main

import (
    "database/sql"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 执行查询
    rows, err := db.Query("SELECT 42")
    if err != nil {
        panic(err)
    }
    defer rows.Close()
}
```

### 高级特性

#### Copy

COPY 函数可以用于导入导出数据：

```go
package main

import (
    "database/sql"
    "fmt"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 1. 创建示例表
    _, err = db.Exec(`
        CREATE TABLE employees (
            id INTEGER,
            name VARCHAR,
            department VARCHAR,
            salary DECIMAL(10,2)
        )
    `)
    if err != nil {
        panic(err)
    }

    // 2. 从 CSV 文件导入数据
    _, err = db.Exec(`
        COPY employees FROM 'data/employees.csv' (
            DELIMITER ',',
            HEADER true,
            NULL 'NULL'
        )
    `)
    if err != nil {
        panic(err)
    }

    // 3. 导出数据到 CSV
    _, err = db.Exec(`
        COPY (
            SELECT * FROM employees 
            WHERE salary > 50000
        ) 
        TO 'data/high_salary_employees.csv' (
            DELIMITER ',',
            HEADER true,
            NULL 'NULL'
        )
    `)
    if err != nil {
        panic(err)
    }

    // 4. 导出到 Parquet 文件
    _, err = db.Exec(`
        COPY employees 
        TO 'data/employees.parquet' (
            FORMAT PARQUET,
            COMPRESSION 'SNAPPY'
        )
    `)
    if err != nil {
        panic(err)
    }

    // 5. 导出查询结果到 JSON
    _, err = db.Exec(`
        COPY (
            SELECT 
                department,
                AVG(salary) as avg_salary,
                COUNT(*) as employee_count
            FROM employees
            GROUP BY department
        ) 
        TO 'data/department_stats.json' (
            FORMAT JSON,
            ARRAY true
        )
    `)
    if err != nil {
        panic(err)
    }

    // 6. 从压缩文件导入
    _, err = db.Exec(`
        COPY employees 
        FROM 'data/employees.csv.gz' (
            DELIMITER ',',
            HEADER true,
            COMPRESSION GZIP
        )
    `)
    if err != nil {
        panic(err)
    }

    // 7. 导出特定列
    _, err = db.Exec(`
        COPY employees (name, salary) 
        TO 'data/salary_info.csv' (
            DELIMITER ',',
            HEADER true
        )
    `)
    if err != nil {
        panic(err)
    }

    // 8. 使用自定义分隔符和引号
    _, err = db.Exec(`
        COPY employees 
        TO 'data/custom_format.csv' (
            DELIMITER '|',
            QUOTE '"',
            ESCAPE '\\',
            HEADER true
        )
    `)
    if err != nil {
        panic(err)
    }
}
```

COPY 函数的主要特性和选项：

 **文件格式支持**：
```sql
-- CSV 格式
COPY table FROM/TO 'file.csv'

-- Parquet 格式
COPY table FROM/TO 'file.parquet' (FORMAT PARQUET)

-- JSON 格式
COPY table FROM/TO 'file.json' (FORMAT JSON)
```

 **压缩选项**：
```sql
-- GZIP 压缩
COPY table FROM/TO 'file.csv.gz' (COMPRESSION GZIP)

-- Parquet with Snappy 压缩
COPY table FROM/TO 'file.parquet' (
    FORMAT PARQUET, 
    COMPRESSION 'SNAPPY'
)
```

 **CSV 格式选项**：
```sql
COPY table FROM/TO 'file.csv' (
    DELIMITER ',',        -- 分隔符
    HEADER true,         -- 是否包含表头
    QUOTE '"',           -- 引号字符
    ESCAPE '\\',         -- 转义字符
    NULL 'NULL',         -- NULL值表示
    FORCE_QUOTE true     -- 强制引号
)
```

 **选择性导出**：
```sql
-- 导出查询结果
COPY (SELECT * FROM table WHERE condition) TO 'file.csv'

-- 导出特定列
COPY table (column1, column2) TO 'file.csv'
```

 **错误处理**：
```go
// 添加错误处理和日志记录
func exportData(db *sql.DB, query, filepath string) error {
    _, err := db.Exec(fmt.Sprintf(`
        COPY (%s) TO '%s' (
            DELIMITER ',',
            HEADER true,
            NULL 'NULL'
        )
    `, query, filepath))
    
    if err != nil {
        return fmt.Errorf("export failed: %w", err)
    }
    
    return nil
}
```

COPY 函数是 DuckDB 中进行数据导入导出的高效方式,可以参考上面部分，根据实际需求选择合适的选项和格式。

#### Appender 接口
Appender 接口提供了高性能的数据插入方式：

```go
package main

import (
    "database/sql"
    "fmt"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 创建表
    db.Exec(`CREATE TABLE users(id INTEGER, name VARCHAR)`)

    // 创建 appender
    appender, err := db.Prepare("APPEND INTO users VALUES (?, ?)")
    if err != nil {
        panic(err)
    }
    defer appender.Close()

    // 批量插入数据
    for i := 0; i < 1000; i++ {
        appender.Exec(i, fmt.Sprintf("user_%d", i))
    }
}
```

#### JSON 处理
DuckDB 提供了强大的 JSON 处理能力：

```go
package main

import (
    "database/sql"
    "fmt"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 查询 JSON 数据
    rows, err := db.Query(`
        SELECT json_extract('{"name": "John"}', '$.name')
    `)
    if err != nil {
        panic(err)
    }
    defer rows.Close()

    for rows.Next() {
        var name string
        rows.Scan(&name)
        fmt.Println("Name:", name)
    }
}
```

#### 自定义函数 (UDF)

##### 标量函数
DuckDB 支持用户定义的标量函数，可以用于自定义计算逻辑：

```go
package main

import (
    "database/sql"
    "fmt"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 注册自定义函数
    db.Exec(`
        CREATE FUNCTION add_one(x INTEGER) 
        RETURNS INTEGER 
        AS 'x + 1'
    `)

    // 使用自定义函数
    rows, err := db.Query("SELECT add_one(41)")
    if err != nil {
        panic(err)
    }
    defer rows.Close()

    for rows.Next() {
        var result int
        rows.Scan(&result)
        fmt.Println("Result:", result) // Output: Result: 42
    }
}
```

##### 表函数
表函数可以返回一个表，适用于生成序列或动态数据集：

```go
package main

import (
    "database/sql"
    "fmt"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 创建表函数
    db.Exec(`
        CREATE TABLE FUNCTION generate_series(start INTEGER, stop INTEGER) 
        AS SELECT * FROM range(start, stop)
    `)

    // 使用表函数
    rows, err := db.Query("SELECT * FROM generate_series(1, 5)")
    if err != nil {
        panic(err)
    }
    defer rows.Close()

    for rows.Next() {
        var number int
        rows.Scan(&number)
        fmt.Println("Number:", number) // Output: 1, 2, 3, 4, 5
    }
}
```

### 性能优化

#### 并行处理
DuckDB 支持并行查询执行：

```go
package main

import (
    "database/sql"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 设置并行度
    db.Exec("SET threads TO 4")

    // 并行查询
    db.Query(`
        SELECT * FROM large_table 
        WHERE id > 1000 
        PARALLEL 4
    `)
}
```

#### 批量操作
使用事务和批处理提高性能：

```go
package main

import (
    "database/sql"
    "fmt"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    tx, err := db.Begin()
    if err != nil {
        panic(err)
    }

    stmt, err := tx.Prepare("INSERT INTO users VALUES (?, ?)")
    if err != nil {
        panic(err)
    }
    defer stmt.Close()

    for i := 0; i < 1000; i++ {
        _, err = stmt.Exec(i, fmt.Sprintf("user_%d", i))
        if err != nil {
            panic(err)
        }
    }

    tx.Commit()
}
```

### 实际应用场景

#### 数据分析
```go
package main

import (
    "database/sql"
    "fmt"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 复杂分析查询
    rows, err := db.Query(`
        SELECT 
            department,
            AVG(salary) as avg_salary,
            COUNT(*) as employee_count
        FROM employees
        GROUP BY department
        HAVING COUNT(*) > 10
        ORDER BY avg_salary DESC
    `)
    if err != nil {
        panic(err)
    }
    defer rows.Close()

    for rows.Next() {
        var department string
        var avgSalary float64
        var employeeCount int
        rows.Scan(&department, &avgSalary, &employeeCount)
        fmt.Printf("Department: %s, Avg Salary: %.2f, Employee Count: %d\n", department, avgSalary, employeeCount)
    }
}
```

####  与其他数据源集成
```go
package main

import (
    "database/sql"
    _ "github.com/marcboeker/go-duckdb"
)

func main() {
    db, err := sql.Open("duckdb", ":memory:")
    if err != nil {
        panic(err)
    }
    defer db.Close()

    // 读取 Parquet 文件
    db.Query(`
        SELECT * 
        FROM read_parquet('data.parquet')
    `)

    // 读取 CSV 文件
    db.Query(`
        SELECT * 
        FROM read_csv('data.csv')
    `)
}
```

### ORM

目前暂时只有gorm的[duckdb驱动](https://github.com/alifiroozi80/duckdb) 

###  最佳实践

1. 使用 Prepared Statements 避免 SQL 注入
2. 适当使用事务提高性能
3. 利用 DuckDB 的并行处理能力
4. 合理设置内存限制
5. 定期维护和优化查询

### 总结

DuckDB 通过其简单的接口和强大的分析能力，为 Go 开发者提供了一个优秀的嵌入式分析数据库解决方案。它特别适合于:
- 数据分析和报表生成
- 嵌入式 OLAP 应用
- 原型开发和测试
- 小型到中型的数据处理任务

参考资源：
- [go-duckdb Examples](https://github.com/marcboeker/go-duckdb/tree/main/examples)
- [A Comprehensive Guide for Using DuckDB With Go](https://hackernoon.com/a-comprehensive-guide-for-using-duckdb-with-go)

## 认识arrow

### parquet

### Flight RPC

## 参考资源

+ [Use Apache Arrow and Go for Your Data Workflows](https://voltrondata.com/blog/use-apache-arrow-and-go-for-your-data-workflows)
+ [Data Transfer with Apache Arrow and Golang](https://voltrondata.com/blog/data-transfer-with-apache-arrow-and-golang)
+ Apache Arrow and Go A match made in Data [ youtube video](https://www.youtube.com/watch?v=ctK9MxDJd2Q)  [slide](https://apachecon.com/acna2022/slides/01_Topol_Arrow_and_Go.pdf)