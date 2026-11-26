/// Convierte un porcentaje de cumplimiento (0–100) en el nivel 0–4 de la escala de color del calendario y de la
/// semana: 0 % → 0 · hasta 34 % → 1 · hasta 69 % → 2 · hasta 99 % → 3 · 100 % → 4.
int nivelDeCumplimiento(double porcentaje) {
  if (porcentaje <= 0) {
    return 0;
  }
  if (porcentaje < 35) {
    return 1;
  }
  if (porcentaje < 70) {
    return 2;
  }
  return porcentaje < 100 ? 3 : 4;
}
