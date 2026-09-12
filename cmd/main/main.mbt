///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
fn main {
  let values = [0.25, -1.0, 0.75, 2.0]
  let (quantized, scale) = @lib.quantize_int8(values)
  let reconstructed = @lib.dequantize_int8(quantized, scale)
  println("MoonQuant Int8 demo")
  println("input: " + values.to_string())
  println("quantized: " + quantized.to_string())
  println("scale: " + scale.to_string())
  println("reconstructed: " + reconstructed.to_string())
  println(
    "mean absolute error: " +
    @lib.mean_absolute_error(values, reconstructed).to_string(),
  )
}
