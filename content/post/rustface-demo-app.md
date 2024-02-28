---
title: "一个RustFace demo程序"
date: 2024-02-27
tags: ["rust"]
draft: false
---

> 下面是一个基于[RustFace](https://github.com/atomashpolskiy/rustface)这个库的demo程序。基于[原项目](https://github.com/andyquinterom/shiny-rs-faceapp) 整理。image随便下载一张，model.bin从原项目进行下载即可。

Cargo.toml配置

```toml
[package]
name = "faceDemo"
version = "0.1.0"
edition = "2021"

# See more keys and their definitions at https://doc.rust-lang.org/cargo/reference/manifest.html

[dependencies]
rustface = "0"
image= "0.23.14"
```

src/main.rs

```rust
use rustface::{Detector, FaceInfo, ImageData};

fn main() {
    let imageFile = "1.png";
    let modelFile = "model.bin";

    let mut detector = rustface::create_detector(modelFile).unwrap();
    detector.set_min_face_size(20);
    detector.set_score_thresh(2.0);
    detector.set_pyramid_scale_factor(0.8);
    detector.set_slide_window_step(4, 4);

   let img =  image::open(imageFile).unwrap();
    let gray = img.to_luma8();
    let (width, height) = gray.dimensions();
    let mut image = ImageData::new(&*gray, width, height);
    for face in detector.detect(&mut image).into_iter() {
        // print confidence score and coordinates
        println!("found face: {:?}", face);
    }
}
// output:
//  found face: FaceInfo { bbox: Rectangle { x: 228, y: 262, width: 582, height: 582 }, roll: 0.0, pitch: 0.0, yaw: 0.0, score: 24.993442237377167 }

```