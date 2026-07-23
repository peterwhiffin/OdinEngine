struct VSOutput {
  float4 Pos : SV_POSITION;
  float2 UV;
};

[shader("vertex")]
VSOutput vertMain(uint vertex_id: SV_VertexID) {
  float2 pos[3] = {
    float2(-1.0, -1.0),
    float2(3.0, -1.0),
    float2(-1.0, 3.0),
  };

  VSOutput output;
  output.Pos = float4(pos[vertex_id], 0.0, 1.0);
  output.UV = pos[vertex_id] * 0.5 + 0.5;
  return output;
}

[shader("fragment")]
float4 fragMain(VSOutput input) {
  float3 final_color = float3(input.UV.x, input.UV.y, 0.0);
  return float4(final_color.rgb, 1.0);
}
