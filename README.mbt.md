# jianjie-lin/MoonQuant

MoonQuant is a dependency-free Int8 tensor quantization library for MoonBit.
It supports symmetric, asymmetric, and per-channel quantization together with
reconstruction metrics, saturation diagnostics, and basic quantized vector
operations.

```moonbit nocheck
let values = [1.0, -2.0, 0.5]
let (encoded, scale) = @MoonQuant.quantize_int8(values)
let decoded = @MoonQuant.dequantize_int8(encoded, scale)
let error = @MoonQuant.mean_absolute_error(values, decoded)
```

See the repository README for the full API overview and runnable example.
