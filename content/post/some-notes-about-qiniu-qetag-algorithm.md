---
title: "关于七牛qetag算法的一些记录"
date: 2024-01-22
tags: ["golang","csharp","qiniu"]
draft: false
---

## 背景

今天做七牛相关接口开发的时候发现七牛的文件查询列表返回，有个`hash`字段，但是不知道是怎么进行计算的。后来查询到七牛的官方仓库 [qetag](https://github.com/qiniu/qetag).官方对这个算法的描述是这样的：

>qetag 是一个计算文件在七牛云存储上的 hash 值（也是文件下载时的 etag 值）的实用程序。
>
>七牛的 hash/etag 算法是公开的。算法大体如下：
>
>- 如果你能够确认文件 <= 4M，那么 hash = UrlsafeBase64([0x16, sha1(FileContent)])。也就是，文件的内容的sha1值（20个字节），前面加一个byte（值为0x16），构成 21 字节的二进制数据，然后对这 21 字节的数据做 urlsafe 的 base64 编码。
>- 如果文件 > 4M，则 hash = UrlsafeBase64([0x96, sha1([sha1(Block1), sha1(Block2), ...])])，其中 Block 是把文件内容切分为 4M 为单位的一个个块，也就是 `BlockI = FileContent[I*4M:(I+1)*4M]`。
>
>为何需要公开 hash/etag 算法？这个和 “消重” 问题有关，详细见：
>
>- https://developer.qiniu.com/kodo/kb/1365/how-to-avoid-the-users-to-upload-files-with-the-same-key
>- http://segmentfault.com/q/1010000000315810
>
>为何在 sha1 值前面加一个byte的标记位(0x16或0x96）？
>
>- 0x16 = 22，而 2^22 = 4M。所以前面的 0x16 其实是文件按 4M 分块的意思。
>- 0x96 = 0x80 | 0x16。其中的 0x80 表示这个文件是大文件（有多个分块），hash 值也经过了2重的 sha1 计算。

## 语言封装

### C# 实现

基于官方仓库的csharp代码做了部分修改

```csharp
public static class QETag
{
	const  int CHUNK_SIZE = 1 << 22;

	private static byte[] sha1(byte[] data)
	{
		return System.Security.Cryptography.SHA1.Create().ComputeHash(data);
	}

	private static String urlSafeBase64Encode(byte[] data)
	{
		String encodedString = Convert.ToBase64String(data);
		encodedString = encodedString.Replace('+', '-').Replace('/', '_');
		return encodedString;
	}

	public static String calcETag(String path)
	{
	    string etag = string.Empty;
		using (FileStream fs = File.OpenRead(path))
		{
			long fileLength = fs.Length;
			if (fileLength <= CHUNK_SIZE)
			{
				byte[] fileData = new byte[(int)fileLength];
				fs.Read(fileData, 0, (int)fileLength);
				byte[] sha1Data = sha1(fileData);
				int sha1DataLen = sha1Data.Length;
				byte[] hashData = new byte[sha1DataLen + 1];

				System.Array.Copy(sha1Data, 0, hashData, 1, sha1DataLen);
				hashData[0] = 0x16;
				etag = urlSafeBase64Encode(hashData);
			}
			else
			{
				int chunkCount = (int)(fileLength / CHUNK_SIZE);
				if (fileLength % CHUNK_SIZE != 0)
				{
					chunkCount += 1;
				}
				byte[] allSha1Data = new byte[0];
				for (int i = 0; i < chunkCount; i++)
				{
					byte[] chunkData = new byte[CHUNK_SIZE];
					int bytesReadLen = fs.Read(chunkData, 0, CHUNK_SIZE);
					byte[] bytesRead = new byte[bytesReadLen];
					System.Array.Copy(chunkData, 0, bytesRead, 0, bytesReadLen);
					byte[] chunkDataSha1 = sha1(bytesRead);
					byte[] newAllSha1Data = new byte[chunkDataSha1.Length
							+ allSha1Data.Length];
					System.Array.Copy(allSha1Data, 0, newAllSha1Data, 0,
							allSha1Data.Length);
					System.Array.Copy(chunkDataSha1, 0, newAllSha1Data,
							allSha1Data.Length, chunkDataSha1.Length);
					allSha1Data = newAllSha1Data;
				}
				byte[] allSha1DataSha1 = sha1(allSha1Data);
				byte[] hashData = new byte[allSha1DataSha1.Length + 1];
				System.Array.Copy(allSha1DataSha1, 0, hashData, 1,
						allSha1DataSha1.Length);
				hashData[0] = (byte)0x96;
				etag = urlSafeBase64Encode(hashData);
			}
		}
		return etag;

	}
}
```
### rust实现
使用ai生成
```rust
use std::io::{self, Read, BufReader};
use std::fs::File;
use sha1::Sha1;
use rustc_serialize::base64::{self, ToBase64, URL_SAFE};

const BLOCK_BITS: u64 = 22;
const BLOCK_SIZE: i64 = 1 << BLOCK_BITS;

fn block_count(fsize: i64) -> i64 {
    (fsize + (BLOCK_SIZE - 1)) >> BLOCK_BITS
}

fn cal_sha1(mut r: impl Read) -> io::Result<Vec<u8>> {
    let mut buffer = Vec::new();
    let mut h = Sha1::new();
    io::copy(&mut r, &mut h)?;
    buffer.extend(h.digest().bytes());
    Ok(buffer)
}

fn get_etag(filename: &str) -> io::Result<String> {
    let f = File::open(filename)?;
    let fsize = f.metadata()?.len() as i64;

    let mut sha1_buf = Vec::new();
    let mut r = BufReader::new(&f);

    if block_count(fsize) <= 1 {
        sha1_buf.push(0x16);
        sha1_buf.extend(cal_sha1(&mut r)?);
    } else {
        sha1_buf.push(0x96);
        let mut sha1_block_buf = Vec::new(); 
        
        for _i in 0..block_count(fsize) {
            let mut body = r.by_ref().take(BLOCK_SIZE as u64);
            sha1_block_buf.extend(cal_sha1(&mut body)?);
        }

        sha1_buf.extend(cal_sha1(io::Cursor::new(sha1_block_buf))?);
    }
    Ok(sha1_buf.to_base64(URL_SAFE))
}

fn main() -> io::Result<()>{
    let etag = get_etag("your_file_path")?;

    println!("{}", etag);
    Ok(())
}
```
你需要添加以下依赖到你的Cargo.toml文件中:

```toml
[dependencies]
sha1 = "0.6.0"
rustc-serialize = "0.3"
```

### Dart实现
ai生成
```dart
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

const int BLOCK_BITS = 22;
const int BLOCK_SIZE = 1 << BLOCK_BITS;


int blockCount(int fsize) {
  return ((fsize + (BLOCK_SIZE-1)) >> BLOCK_BITS);
}

Future<List<int>> calSha1(List<int> b, Stream<List<int>> r) async {

  Digest digest = await sha1.bind(r).first;
  b.addAll(digest.bytes);
  return b;
}

Future<String> getEtag(String filename) async {

  var f = File(filename);
  await f.open();
  int fsize = await f.length();
  
  int blockCnt = blockCount(fsize);
  List<int> sha1Buf = [];

  var openReadStream = f.openRead();
  if (blockCnt <= 1) { // file size <= 4M
    sha1Buf.add(0x16);
    sha1Buf = await calSha1(sha1Buf, openReadStream); 
  } else { // file size > 4M
    sha1Buf.add(0x96);
    List<int> sha1BlockBuf = [];
    for (int i = 0; i < blockCnt; i ++) {
      var body = openReadStream.take(BLOCK_SIZE);
      sha1BlockBuf = await calSha1(sha1BlockBuf, body);
    }
    sha1Buf = await calSha1(sha1Buf, Stream.fromIterable([sha1BlockBuf]));
  }
  String etag = base64UrlEncode(sha1Buf);
  return etag;
}

void main() async {
  String etag = await getEtag('your_file_path');
  print(etag);
}
```

请注意, 这段代码需要 'crypto' 这个库来实现sha1的计算. 你可以通过在pubspec.yaml文件添加以下一行来获取这个库：
```dart
dependencies:
  crypto: any
```

