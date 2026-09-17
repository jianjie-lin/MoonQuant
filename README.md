# MoonQuant

A small, dependency-free tensor quantization foundation for MoonBit.

## Overview

MoonQuant provides building blocks for reducing model-weight memory and data
transfer costs in WebAssembly, edge, and other resource-constrained
applications. It focuses on a well-tested Int8 baseline rather than claiming
to be a complete model runtime.

## Quick start

```moonbit
let values = [1.0, -2.0, 0.5]
let (encoded, scale) = @MoonQuant.quantize_int8(values)
let decoded = @MoonQuant.dequantize_int8(encoded, scale)
let error = @MoonQuant.mean_absolute_error(values, decoded)
let worst = @MoonQuant.max_absolute_error(values, decoded)
let clipped = @MoonQuant.saturation_count(values, scale)

let (affine, affine_scale, zero_point) =
  @MoonQuant.quantize_int8_asymmetric(values)
let affine_decoded =
  @MoonQuant.dequantize_int8_asymmetric(affine, affine_scale, zero_point)
```

Run the included demonstration with:

```bash
moon run cmd/main
```

The quantizer uses a symmetric range of -127..127. For an all-zero or empty
input, the scale is `1.0`; this keeps the API safe from division by zero.
`quantize_int8_with_scale` supports reusing a scale across batches, while
`quantize_int8_per_channel` computes independent scales for consecutive
channels. MAE, MSE, maximum error, and RMSE helpers are available for
evaluating reconstruction quality. Saturation diagnostics help identify an
undersized scale, and quantized dot product and cosine similarity support
basic vector evaluation without reconstructing every value.

## Scope and roadmap

The current release provides symmetric and affine Int8 quantization,
per-channel scales and round trips, reconstruction metrics, quantized vector
operations, and safe handling of degenerate inputs. It does not yet load
ONNX/Safetensors files or run complete LLMs.

Planned extensions are quantized matrix operations, a compact weight format,
and a small end-to-end inference example. Each extension will be accompanied
by accuracy tests and reproducible benchmarks.

## Development

```bash
moon test
moon info
moon fmt
```
