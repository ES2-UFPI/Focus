"""Funções estatísticas em Python puro para o módulo de Insights.

Sem numpy/scipy de propósito: o `requirements.txt` do backend é enxuto e o
volume de dados por aluno é pequeno (dezenas de sessões/semana). A abordagem
aprovada em `docs/plano-backend-insights.md` é deliberadamente leve —
correlação, comparação de médias por grupo e regressão de baixo grau.
"""

from math import sqrt


def media(valores):
    """Média aritmética; 0.0 para lista vazia."""
    valores = list(valores)
    if not valores:
        return 0.0
    return sum(valores) / len(valores)


def _ranks(valores):
    """Ranks 1..n com média em empates (para Spearman)."""
    indexados = sorted(range(len(valores)), key=lambda i: valores[i])
    ranks = [0.0] * len(valores)
    i = 0
    while i < len(indexados):
        j = i
        while j + 1 < len(indexados) and valores[indexados[j + 1]] == valores[indexados[i]]:
            j += 1
        rank_medio = (i + j) / 2 + 1  # ranks começam em 1
        for k in range(i, j + 1):
            ranks[indexados[k]] = rank_medio
        i = j + 1
    return ranks


def pearson(xs, ys):
    """Correlação de Pearson. Retorna None se indefinida (n<2 ou variância 0)."""
    xs = list(xs)
    ys = list(ys)
    n = len(xs)
    if n < 2 or n != len(ys):
        return None
    mx, my = media(xs), media(ys)
    num = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
    den_x = sqrt(sum((x - mx) ** 2 for x in xs))
    den_y = sqrt(sum((y - my) ** 2 for y in ys))
    if den_x == 0 or den_y == 0:
        return None
    return num / (den_x * den_y)


def spearman(xs, ys):
    """Correlação de Spearman (Pearson sobre os ranks).

    É a escolha padrão para produtividade, que é ordinal (nota 1-5), não
    intervalar de verdade.
    """
    xs = list(xs)
    ys = list(ys)
    if len(xs) < 2 or len(xs) != len(ys):
        return None
    return pearson(_ranks(xs), _ranks(ys))


def regressao_quadratica(xs, ys):
    """Ajuste de mínimos quadrados para y = a·x² + b·x + c.

    Usada só quando há hipótese de "ponto ideal" (relação não monotônica),
    hoje essencialmente `duracao_ideal`. Retorna (a, b, c) ou None.
    """
    xs = list(xs)
    ys = list(ys)
    n = len(xs)
    if n < 3:
        return None

    # Somatórios das potências de x necessários para as equações normais.
    s0 = n
    s1 = sum(xs)
    s2 = sum(x ** 2 for x in xs)
    s3 = sum(x ** 3 for x in xs)
    s4 = sum(x ** 4 for x in xs)
    t0 = sum(ys)
    t1 = sum(x * y for x, y in zip(xs, ys))
    t2 = sum((x ** 2) * y for x, y in zip(xs, ys))

    # Sistema linear 3x3: A · [a b c]^T = t  (A montada na ordem a, b, c).
    A = [
        [s4, s3, s2],
        [s3, s2, s1],
        [s2, s1, s0],
    ]
    t = [t2, t1, t0]
    solucao = _resolver_sistema_3x3(A, t)
    if solucao is None:
        return None
    return tuple(solucao)


def vertice_parabola(a, b):
    """x do vértice de a·x²+b·x+c. None se não for parábola (a≈0)."""
    if abs(a) < 1e-12:
        return None
    return -b / (2 * a)


def _resolver_sistema_3x3(A, b):
    """Eliminação de Gauss com pivotamento parcial para um sistema 3x3."""
    # Matriz aumentada, com cópias para não mutar a entrada.
    m = [list(A[i]) + [b[i]] for i in range(3)]

    for coluna in range(3):
        # Pivotamento parcial: maior valor absoluto na coluna.
        pivo = max(range(coluna, 3), key=lambda r: abs(m[r][coluna]))
        if abs(m[pivo][coluna]) < 1e-12:
            return None
        m[coluna], m[pivo] = m[pivo], m[coluna]

        for linha in range(3):
            if linha == coluna:
                continue
            fator = m[linha][coluna] / m[coluna][coluna]
            for c in range(coluna, 4):
                m[linha][c] -= fator * m[coluna][c]

    return [m[i][3] / m[i][i] for i in range(3)]


def variacao_percentual(antes, depois):
    """Variação percentual de `antes` para `depois`, arredondada. 0 se base 0."""
    if antes == 0:
        return 0
    return round((depois - antes) / abs(antes) * 100)
