///|
pub fn find_scale(values : Array[Double]) -> Double {
  let mut max_abs = 0.0

  for x in values {
    let a = if x < 0.0 { -x } else { x }
    if a > max_abs {
      max_abs = a
    }
  }

  if max_abs == 0.0 {
    1.0
  } else {
    max_abs / 127.0
  }
}

///|
pub fn quantize_int8(values : Array[Double]) -> (Array[Int], Double) {
  let scale = find_scale(values)
  (quantize_int8_with_scale(values, scale), scale)
}

///|
/// Quantize values with a caller-provided scale.
/// A non-positive scale is replaced with `1.0` to avoid division by zero.
pub fn quantize_int8_with_scale(
  values : Array[Double],
  scale : Double,
) -> Array[Int] {
  let safe_scale = if scale > 0.0 { scale } else { 1.0 }
  let result = Array::make(values.length(), 0)

  for i = 0; i < values.length(); i = i + 1 {
    let rounded = (values[i] / safe_scale).round().to_int()
    result[i] = if rounded > 127 {
      127
    } else if rounded < -127 {
      -127
    } else {
      rounded
    }
  }

  result
}

///|
pub fn dequantize_int8(values : Array[Int], scale : Double) -> Array[Double] {
  let result = Array::make(values.length(), 0.0)

  for i = 0; i < values.length(); i = i + 1 {
    result[i] = values[i].to_double() * scale
  }

  result
}

///|
/// Calculate the mean absolute reconstruction error.
pub fn mean_absolute_error(
  original : Array[Double],
  reconstructed : Array[Double],
) -> Double {
  let count = if original.length() < reconstructed.length() {
    original.length()
  } else {
    reconstructed.length()
  }
  if count == 0 {
    0.0
  } else {
    let mut total = 0.0
    for i = 0; i < count; i = i + 1 {
      let difference = original[i] - reconstructed[i]
      let absolute = if difference < 0.0 { -difference } else { difference }
      total = total + absolute
    }
    total / count.to_double()
  }
}

///|
/// Return the largest absolute reconstruction error.
pub fn max_absolute_error(
  original : Array[Double],
  reconstructed : Array[Double],
) -> Double {
  let count = if original.length() < reconstructed.length() {
    original.length()
  } else {
    reconstructed.length()
  }
  let mut maximum = 0.0
  for i = 0; i < count; i = i + 1 {
    let difference = original[i] - reconstructed[i]
    let absolute = if difference < 0.0 { -difference } else { difference }
    if absolute > maximum {
      maximum = absolute
    }
  }
  maximum
}

///|
/// Return the root mean square reconstruction error.
pub fn root_mean_square_error(
  original : Array[Double],
  reconstructed : Array[Double],
) -> Double {
  let count = if original.length() < reconstructed.length() {
    original.length()
  } else {
    reconstructed.length()
  }
  if count == 0 {
    0.0
  } else {
    let mut squared_total = 0.0
    for i = 0; i < count; i = i + 1 {
      let difference = original[i] - reconstructed[i]
      squared_total = squared_total + difference * difference
    }
    (squared_total / count.to_double()).sqrt()
  }
}

///|
/// Quantize and immediately reconstruct values.
pub fn quantize_dequantize(values : Array[Double]) -> (Array[Double], Double) {
  let (quantized, scale) = quantize_int8(values)
  (dequantize_int8(quantized, scale), scale)
}

///|
/// Quantize values with an asymmetric Int8 affine mapping.
/// The returned tuple is (quantized values, scale, zero point).
pub fn quantize_int8_asymmetric(
  values : Array[Double],
) -> (Array[Int], Double, Int) {
  if values.length() == 0 {
    return ([], 1.0, 0)
  }
  let mut minimum = values[0]
  let mut maximum = values[0]
  for value in values {
    if value < minimum {
      minimum = value
    }
    if value > maximum {
      maximum = value
    }
  }
  if maximum == minimum {
    // Keep constant inputs reconstructible without a division by zero.
    let zero_point = (-minimum).round().to_int()
    return (Array::make(values.length(), 0), 1.0, zero_point)
  }
  let scale = (maximum - minimum) / 254.0
  let zero_point = (-minimum / scale).round().to_int() - 127
  let result = Array::make(values.length(), 0)
  for i = 0; i < values.length(); i = i + 1 {
    let rounded = (values[i] / scale).round().to_int() + zero_point
    result[i] = if rounded > 127 {
      127
    } else if rounded < -127 {
      -127
    } else {
      rounded
    }
  }
  (result, scale, zero_point)
}

///|
/// Reconstruct values produced by `quantize_int8_asymmetric`.
pub fn dequantize_int8_asymmetric(
  values : Array[Int],
  scale : Double,
  zero_point : Int,
) -> Array[Double] {
  let result = Array::make(values.length(), 0.0)
  for i = 0; i < values.length(); i = i + 1 {
    result[i] = (values[i] - zero_point).to_double() * scale
  }
  result
}

///|
/// Quantize consecutive fixed-size channels independently.
/// Returns one scale per channel and preserves the input layout.
pub fn quantize_int8_per_channel(
  values : Array[Double],
  channel_size : Int,
) -> (Array[Int], Array[Double]) {
  if channel_size <= 0 || values.length() == 0 {
    return ([], [])
  }
  let channels = (values.length() + channel_size - 1) / channel_size
  let result = Array::make(values.length(), 0)
  let scales = Array::make(channels, 1.0)
  for channel = 0; channel < channels; channel = channel + 1 {
    let start = channel * channel_size
    let end = if start + channel_size < values.length() {
      start + channel_size
    } else {
      values.length()
    }
    let mut maximum = 0.0
    for i = start; i < end; i = i + 1 {
      let absolute = if values[i] < 0.0 { -values[i] } else { values[i] }
      if absolute > maximum {
        maximum = absolute
      }
    }
    let scale = if maximum == 0.0 { 1.0 } else { maximum / 127.0 }
    scales[channel] = scale
    for i = start; i < end; i = i + 1 {
      let rounded = (values[i] / scale).round().to_int()
      result[i] = if rounded > 127 {
        127
      } else if rounded < -127 {
        -127
      } else {
        rounded
      }
    }
  }
  (result, scales)
}

///|
/// Reconstruct values quantized by `quantize_int8_per_channel`.
pub fn dequantize_int8_per_channel(
  values : Array[Int],
  scales : Array[Double],
  channel_size : Int,
) -> Array[Double] {
  let result = Array::make(values.length(), 0.0)
  if channel_size <= 0 {
    return result
  }
  for i = 0; i < values.length(); i = i + 1 {
    let channel = i / channel_size
    let scale = if channel < scales.length() { scales[channel] } else { 1.0 }
    result[i] = values[i].to_double() * scale
  }
  result
}

///|
/// Quantize and reconstruct consecutive channels in one operation.
pub fn quantize_dequantize_per_channel(
  values : Array[Double],
  channel_size : Int,
) -> (Array[Double], Array[Double]) {
  let (quantized, scales) = quantize_int8_per_channel(values, channel_size)
  (dequantize_int8_per_channel(quantized, scales, channel_size), scales)
}

///|
/// Mean squared reconstruction error.
pub fn mean_squared_error(
  original : Array[Double],
  reconstructed : Array[Double],
) -> Double {
  let count = if original.length() < reconstructed.length() {
    original.length()
  } else {
    reconstructed.length()
  }
  if count == 0 {
    return 0.0
  }
  let mut total = 0.0
  for i = 0; i < count; i = i + 1 {
    let difference = original[i] - reconstructed[i]
    total = total + difference * difference
  }
  total / count.to_double()
}

///|
/// Calculate the idealized storage reduction of Float64 values to Int8.
pub fn storage_reduction_ratio(value_count : Int) -> Double {
  if value_count <= 0 {
    1.0
  } else {
    8.0
  }
}

///|
/// Calculate the dot product of two symmetric Int8 vectors.
/// Only the shared prefix is used when the input lengths differ.
pub fn quantized_dot_product(
  left : Array[Int],
  left_scale : Double,
  right : Array[Int],
  right_scale : Double,
) -> Double {
  let count = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  let mut integer_sum = 0
  for i = 0; i < count; i = i + 1 {
    integer_sum = integer_sum + left[i] * right[i]
  }
  integer_sum.to_double() * left_scale * right_scale
}

///|
/// Calculate cosine similarity directly from two Int8 vectors.
/// Returns zero when either vector has no magnitude.
pub fn quantized_cosine_similarity(
  left : Array[Int],
  right : Array[Int],
) -> Double {
  let count = if left.length() < right.length() {
    left.length()
  } else {
    right.length()
  }
  let mut dot = 0.0
  let mut left_squared = 0.0
  let mut right_squared = 0.0
  for i = 0; i < count; i = i + 1 {
    let left_value = left[i].to_double()
    let right_value = right[i].to_double()
    dot = dot + left_value * right_value
    left_squared = left_squared + left_value * left_value
    right_squared = right_squared + right_value * right_value
  }
  if left_squared == 0.0 || right_squared == 0.0 {
    0.0
  } else {
    dot / (left_squared.sqrt() * right_squared.sqrt())
  }
}

///|
/// Count values that exceed the representable symmetric Int8 range.
pub fn saturation_count(values : Array[Double], scale : Double) -> Int {
  let safe_scale = if scale > 0.0 { scale } else { 1.0 }
  let limit = 127.0 * safe_scale
  let mut count = 0
  for value in values {
    if value > limit || value < -limit {
      count = count + 1
    }
  }
  count
}

///|
/// Return the share of values that exceed the symmetric Int8 range.
pub fn saturation_ratio(values : Array[Double], scale : Double) -> Double {
  if values.length() == 0 {
    0.0
  } else {
    saturation_count(values, scale).to_double() / values.length().to_double()
  }
}
