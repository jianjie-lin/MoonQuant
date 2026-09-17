///|
/// Compare the reconstruction error of the supported Int8 strategies.
fn main {
  let values = [0.25, -1.0, 0.75, 2.0, 18.0, -24.0]
  let (symmetric, symmetric_scale) = @lib.quantize_dequantize(values)
  let (asymmetric_values, asymmetric_scale, zero_point) = @lib.quantize_int8_asymmetric(
    values,
  )
  let asymmetric = @lib.dequantize_int8_asymmetric(
    asymmetric_values, asymmetric_scale, zero_point,
  )
  let (per_channel, scales) = @lib.quantize_dequantize_per_channel(values, 2)

  println("MoonQuant Int8 strategy comparison")
  println("sample count: " + values.length().to_string())
  println("symmetric scale: " + symmetric_scale.to_string())
  println(
    "symmetric MAE: " + @lib.mean_absolute_error(values, symmetric).to_string(),
  )
  println("asymmetric scale: " + asymmetric_scale.to_string())
  println("asymmetric zero point: " + zero_point.to_string())
  println(
    "asymmetric MAE: " +
    @lib.mean_absolute_error(values, asymmetric).to_string(),
  )
  println("per-channel groups: " + scales.length().to_string())
  println(
    "per-channel MAE: " +
    @lib.mean_absolute_error(values, per_channel).to_string(),
  )
}
