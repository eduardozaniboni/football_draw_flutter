import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

class Person {
  String name;
  int attack;
  int defense;

  Person({required this.name, required this.attack, required this.defense});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sorteador de Times',
      theme: ThemeData(
        primaryColor: Colors.green[900], // Verde escuro
        scaffoldBackgroundColor: Colors.blueGrey[50], // Cinza azulado claro
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.green[900]), // Verde escuro
          bodyLarge: const TextStyle(color: Colors.black87), // Preto
        ),
      ),
      home: const MyHomePage(title: 'Sorteador de Times'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Person> people = [];
  List<int> teamScores = [];
  // Novo: Adicionado para armazenar os times e seus membros
  List<List<Person>> teams = []; // Armazena os times e seus jogadores

  TextEditingController nameController = TextEditingController();
  TextEditingController attackController = TextEditingController();
  TextEditingController defenseController = TextEditingController();
  TextEditingController teamSizeController = TextEditingController();

  void addPerson() {
    setState(() {
      String name = nameController.text;
      int attack = int.tryParse(attackController.text) ?? 0;
      int defense = int.tryParse(defenseController.text) ?? 0;
      people.add(Person(name: name, attack: attack, defense: defense));
      nameController.clear();
      attackController.clear();
      defenseController.clear();
    });
  }

  void sortTeams() {
    setState(() {
      int teamSize = int.tryParse(teamSizeController.text) ?? 0;
      int numPlayers = people.length;
      int numTeams = (numPlayers / teamSize).ceil();

      // Ordenar os jogadores com base na soma de ataque e defesa
      List<Person> sortedPlayers = List.from(people)
        ..sort(
            (a, b) => (a.attack + a.defense).compareTo(b.attack + b.defense));

      // Distribuir os jogadores entre os times (modificado para armazenar os times)
      teams = List.generate(numTeams, (_) => []);
      for (int i = 0; i < sortedPlayers.length; i++) {
        int lowestScoreIndex = findLowestScoreIndex(teams);
        teams[lowestScoreIndex].add(sortedPlayers[i]);
      }

      // Calcular as pontuações dos times e armazenar os times
      teamScores.clear();
      for (int i = 0; i < numTeams; i++) {
        int teamScore = teams[i].fold(
            0,
            (previousValue, element) =>
                previousValue + element.attack + element.defense);
        teamScores.add(teamScore);
      }
    });
  }

  int findLowestScoreIndex(List<List<Person>> teams) {
    int lowestScoreIndex = 0;
    int lowestScore = calculateScore(teams[0]);
    for (int i = 1; i < teams.length; i++) {
      int score = calculateScore(teams[i]);
      if (score < lowestScore) {
        lowestScore = score;
        lowestScoreIndex = i;
      }
    }
    return lowestScoreIndex;
  }

  int calculateScore(List<Person> team) {
    return team.fold(
        0,
        (previousValue, element) =>
            previousValue + element.attack + element.defense);
  }

  void saveList() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null) {
      PlatformFile file = result.files.first;
      String jsonText = jsonEncode(people);
      try {
        File fileToSave = File(file.path!);
        await fileToSave.writeAsString(jsonText);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista salva com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar lista: $e')),
        );
      }
    }
  }

  void importList() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null) {
      try {
        PlatformFile file = result.files.first;
        List<int> bytes = file.bytes!;
        String jsonText = utf8.decode(bytes);
        Map<String, dynamic> jsonData = jsonDecode(jsonText);

        // Acessar a chave "people" e converter para uma lista de pessoas
        List<dynamic> peopleData = jsonData['people'];

        setState(() {
          people = peopleData
              .map((personData) => Person(
                    name: personData['name'],
                    attack: personData['attack'],
                    defense: personData['defense'],
                  ))
              .toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lista importada com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar lista: $e')),
        );
        debugPrint('Erro: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    cursorColor:
                        const Color.fromARGB(255, 9, 95, 13), // Cor do cursor
                    cursorWidth: 2.0,
                    decoration: const InputDecoration(
                        labelText: 'Nome',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(
                                255, 9, 95, 13)), // Cor do texto do rótulo
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 9, 95, 13))),
                        contentPadding: EdgeInsets.only(left: 8.0)),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: attackController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor:
                        const Color.fromARGB(255, 9, 95, 13), // Cor do cursor
                    cursorWidth: 2.0,
                    decoration: const InputDecoration(
                        labelText: 'Ataque',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(
                                255, 9, 95, 13)), // Cor do texto do rótulo
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 9, 95, 13))),
                        contentPadding: EdgeInsets.only(left: 8.0)),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: defenseController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor:
                        const Color.fromARGB(255, 9, 95, 13), // Cor do cursor
                    cursorWidth: 2.0,
                    decoration: const InputDecoration(
                        labelText: 'Defesa',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(
                                255, 9, 95, 13)), // Cor do texto do rótulo
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 9, 95, 13))),
                        contentPadding: EdgeInsets.only(left: 8.0)),
                  ),
                ),
                ElevatedButton(
                  onPressed: addPerson,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.green), // Cor de fundo laranja
                  ),
                  child: const Text(
                    'Adicionar',
                    style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: teamSizeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    cursorColor:
                        const Color.fromARGB(255, 9, 95, 13), // Cor do cursor
                    cursorWidth: 2.0,
                    decoration: const InputDecoration(
                        labelText: 'Número de pessoas por time',
                        labelStyle: TextStyle(
                            color: Color.fromARGB(
                                255, 9, 95, 13)), // Cor do texto do rótulo
                        focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 9, 95, 13))),
                        contentPadding: EdgeInsets.only(left: 8.0)),
                  ),
                ),
                ElevatedButton(
                  onPressed: sortTeams,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.green), // Cor de fundo laranja
                  ),
                  child: const Text(
                    'Sortear',
                    style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: saveList,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.green), // Cor de fundo
              ),
              child: const Text(
                'Salvar Lista',
                style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: importList,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.green), // Cor de fundo
              ),
              child: const Text(
                'Importar Lista',
                style: TextStyle(color: Color.fromRGBO(255, 255, 255, 1)),
              ),
            ),
            const SizedBox(height: 30),
            // Exibe as pessoas adicionadas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pessoas adicionadas (${people.length}):',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 5),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: people.length,
                  itemExtent: 25, // Defina a altura desejada para cada item
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                          '${index + 1}. ${people[index].name} - Ataque: ${people[index].attack}, Defesa: ${people[index].defense}'),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 50),
            // Modificado para exibir os times e seus membros
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pontuações dos times:',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                // Itera sobre cada time para exibir seus membros e pontuação
                ...teams.asMap().entries.map((entry) {
                  int teamIndex = entry.key;
                  List<Person> teamMembers = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Time ${teamIndex + 1}: ${teamScores[teamIndex]} pontos',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      ...teamMembers.map((person) => Text(
                          '${person.name} - Ataque: ${person.attack}, Defesa: ${person.defense}')),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
