import 'package:flutter/material.dart';

class MateriaisScreen extends StatelessWidget {
  const MateriaisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Paleta de materiais
    final materiais = [
      {
        'titulo': 'Cálculo I – Limites e Derivadas',
        'tipo': 'PDF / Livro',
        'disciplina': 'Cálculo Diferencial',
        'icon': Icons.picture_as_pdf,
        'color': const Color(0xFFE53935),
        'progresso': 0.75,
      },
      {
        'titulo': 'Introdução a Bancos de Dados Relacionais',
        'tipo': 'Slides de Aula',
        'disciplina': 'Banco de Dados',
        'icon': Icons.slideshow_rounded,
        'color': const Color(0xFFFFB300),
        'progresso': 0.40,
      },
      {
        'titulo': 'Playlist: Mecânica Geral Clássica',
        'tipo': 'Vídeo / Playlist',
        'disciplina': 'Física I',
        'icon': Icons.play_circle_fill_rounded,
        'color': const Color(0xFF1E88E5),
        'progresso': 0.90,
      },
      {
        'titulo': 'Folha de Fórmulas – Álgebra Linear',
        'tipo': 'Documento / Resumo',
        'disciplina': 'Álgebra Linear',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF8E24AA),
        'progresso': 0.15,
      },
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Estilizado com Gradiente
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Materiais de Estudo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                  fontSize: 20,
                  shadows: const [
                    Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 4),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3F51B5), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Icon(
                      Icons.folder_open_rounded,
                      size: 80,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Barra de Pesquisa Mockada
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
                          hintText: 'Pesquisar em seus materiais...',
                          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(Icons.tune_rounded, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
          ),

          // Título da Seção
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Adicionados Recentemente',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
            ),
          ),

          // Grid de Materiais
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final mat = materiais[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (mat['color'] as Color).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              mat['icon'] as IconData,
                              color: mat['color'] as Color,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mat['titulo'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      mat['tipo'] as String,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[400],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        mat['disciplina'] as String,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: mat['progresso'] as double,
                                    color: mat['color'] as Color,
                                    backgroundColor: Colors.grey[200],
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: materiais.length,
              ),
            ),
          ),

          // Espaço adicional
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: const Icon(Icons.add_to_photos_rounded),
      ),
    );
  }
}
