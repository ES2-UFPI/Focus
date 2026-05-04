import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FocusApp());
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus',
      debugShowCheckedModeBanner: false,
      home: const ComunicacaoServidorPage(),
    );
  }
}

class ComunicacaoServidorPage extends StatefulWidget {
  const ComunicacaoServidorPage({super.key});

  @override
  State<ComunicacaoServidorPage> createState() =>
      _ComunicacaoServidorPageState();
}

class _ComunicacaoServidorPageState extends State<ComunicacaoServidorPage> {
  String resultado = 'Nenhuma requisição feita ainda.';

  Future<void> buscarTarefa() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/todos/1');

    final resposta = await http.get(url);

    if (resposta.statusCode == 200) {
      final dados = jsonDecode(resposta.body);

      setState(() {
        resultado = 'Tarefa recebida: ${dados['title']}';
      });
    } else {
      setState(() {
        resultado = 'Erro ao buscar dados do servidor.';
      });
    }
  }

  Future<void> enviarTarefa() async {
    final url = Uri.parse('https://jsonplaceholder.typicode.com/todos');

    final resposta = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': 'Estudar Flutter',
        'completed': false,
        'userId': 1,
      }),
    );

    if (resposta.statusCode == 201) {
      setState(() {
        resultado = 'Tarefa enviada com sucesso!';
      });
    } else {
      setState(() {
        resultado = 'Erro ao enviar tarefa.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunicação com Servidor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              resultado,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: buscarTarefa,
              child: const Text('Buscar tarefa do servidor'),
            ),
            ElevatedButton(
              onPressed: enviarTarefa,
              child: const Text('Enviar tarefa para o servidor'),
            ),
          ],
        ),
      ),
    );
  }
}