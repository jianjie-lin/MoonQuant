// Blackbox tests run against the package's public API. Use `@MoonQuant` to import.
// Prefer high-level behaviors over implementation details.
// Run `moon test` to execute and `moon test --update` to refresh snapshots.

///|
test "find scale and round trip" {
  let values = [1.0, -2.0, 0.5]
  let (quantized, scale) = @MoonQuant.quantize_int8(values)
  assert_eq(scale, 2.0 / 127.0)
  assert_eq(quantized[0], 64)
  assert_eq(quantized[1], -127)
  let reconstructed = @MoonQuant.dequantize_int8(quantized, scale)
  assert_true(@MoonQuant.mean_absolute_error(values, reconstructed) < 0.02)
  assert_true(@MoonQuant.max_absolute_error(values, reconstructed) < 0.02)
  assert_true(@MoonQuant.root_mean_square_error(values, reconstructed) < 0.02)
}

///|
test "zero and empty inputs" {
  assert_eq(@MoonQuant.find_scale([]), 1.0)
  let (quantized, scale) = @MoonQuant.quantize_int8([0.0, 0.0])
  assert_eq(scale, 1.0)
  assert_eq(quantized[0], 0)
  assert_eq(quantized[1], 0)
  let (reconstructed, _) = @MoonQuant.quantize_dequantize([])
  assert_eq(reconstructed.length(), 0)
}

///|
test "caller supplied scale and clipping" {
  let quantized = @MoonQuant.quantize_int8_with_scale(
    [0.0, 1.0, -2.0, 200.0],
    1.0,
  )
  assert_eq(quantized[0], 0)
  assert_eq(quantized[1], 1)
  assert_eq(quantized[2], -2)
  assert_eq(quantized[3], 127)
  let safe = @MoonQuant.quantize_int8_with_scale([2.0], 0.0)
  assert_eq(safe[0], 2)
}

///|
test "asymmetric quantization" {
  let values = [-1.0, 0.0, 3.0]
  let (encoded, scale, zero_point) = @MoonQuant.quantize_int8_asymmetric(values)
  let decoded = @MoonQuant.dequantize_int8_asymmetric(
    encoded, scale, zero_point,
  )
  assert_true(decoded[0] < -0.98)
  assert_true(decoded[2] > 2.98)
  assert_true(@MoonQuant.mean_absolute_error(values, decoded) < 0.02)
  let (constant, constant_scale, constant_zero) = @MoonQuant.quantize_int8_asymmetric([
      3.0, 3.0,
    ],
  )
  let constant_decoded = @MoonQuant.dequantize_int8_asymmetric(
    constant, constant_scale, constant_zero,
  )
  assert_true(
    @MoonQuant.max_absolute_error([3.0, 3.0], constant_decoded) < 0.01,
  )
}

///|
test "per channel quantization" {
  let values = [1.0, -2.0, 10.0, -20.0]
  let (encoded, scales) = @MoonQuant.quantize_int8_per_channel(values, 2)
  assert_eq(scales.length(), 2)
  let decoded = @MoonQuant.dequantize_int8_per_channel(encoded, scales, 2)
  assert_true(@MoonQuant.max_absolute_error(values, decoded) < 0.1)
}

///|
test "invalid channel size is safe" {
  let (encoded, scales) = @MoonQuant.quantize_int8_per_channel([1.0], 0)
  assert_eq(encoded.length(), 0)
  assert_eq(scales.length(), 0)
  assert_eq(@MoonQuant.mean_squared_error([], []), 0.0)
}

///|
test "storage reduction estimate" {
  assert_eq(@MoonQuant.storage_reduction_ratio(100), 8.0)
  assert_eq(@MoonQuant.storage_reduction_ratio(0), 1.0)
}

///|
test "quantized dot product" {
  let left = [1.0, -2.0, 0.5]
  let right = [2.0, 1.0, -1.0]
  let (left_quantized, left_scale) = @MoonQuant.quantize_int8(left)
  let (right_quantized, right_scale) = @MoonQuant.quantize_int8(right)
  let result = @MoonQuant.quantized_dot_product(
    left_quantized, left_scale, right_quantized, right_scale,
  )
  assert_true(result > -0.55 && result < -0.45)
  assert_eq(@MoonQuant.quantized_dot_product([], 1.0, [1], 1.0), 0.0)
}
