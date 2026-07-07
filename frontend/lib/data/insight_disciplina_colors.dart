/// Paleta local das disciplinas usadas no preview de insights.
///
/// Os valores seguem o mesmo formato hexadecimal de `Disciplina.cor`. A
/// resolução fica separada da fonte de insights para que ambas possam ser
/// substituídas independentemente no futuro.
const Map<String, String> insightDisciplinaCoresLocais = {
  'Estruturas de Dados': '#2563EB',
  'Banco de Dados': '#F59E0B',
};

String? getInsightDisciplinaColorHex(String? disciplina) {
  return insightDisciplinaCoresLocais[disciplina];
}
