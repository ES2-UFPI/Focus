/// Paleta local das disciplinas usadas no preview de insights.
///
/// Os valores seguem o mesmo formato hexadecimal de `Disciplina.cor`. A
/// resolução fica separada da fonte de insights para que ambas possam ser
/// substituídas independentemente no futuro.
const Map<String, String> insightDisciplinaCoresLocais = {
  'Cálculo': '#4CAF50',
  'Banco de Dados': '#F59E0B',
  'ES2': '#6366F1',
  'Física': '#EC407A',
};

String? getInsightDisciplinaColorHex(String? disciplina) {
  return insightDisciplinaCoresLocais[disciplina];
}
