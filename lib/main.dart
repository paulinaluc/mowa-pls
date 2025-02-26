import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mowa PLS',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterTts flutterTts = FlutterTts();
  String selectedCategory = "Główne";
  Map<String, List<String>> categoryPhrases = {
    "Główne": ["Cześć", "Jak się masz?", "Tak", "Nie", "Nie wiem"],
    "Zakupy": [
      "Będę korzystać z telefonu do rozmowy.",
      "Ile to kosztuje?",
      "Zapłacę kartą.",
      "Czy mogę kupić .....?",
      "Dzień dobry",
      "Do widzenia",
      "Dziękuję"
    ],
    "Wizyta u lekarza": [
      "Dzień dobry",
      "Czy mogę poprosić o receptę?",
      "Czy mogłaby Pani zanotować?"
    ]
  };
  List<TextEditingController> textControllers = [];
  TextEditingController categoryNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedPhrases();
    categoryNameController.text = selectedCategory;
    _setFemaleVoice();
  }

  Future<void> _loadSavedPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    categoryPhrases.forEach((key, value) {
      final savedList = prefs.getStringList(key);
      if (savedList != null) {
        categoryPhrases[key] = savedList;
      }
    });
    setState(() {
      _updatePhraseControllers();
    });
  }

  Future<void> _savePhrases() async {
    final prefs = await SharedPreferences.getInstance();
    categoryPhrases.forEach((key, value) {
      prefs.setStringList(key, value);
    });
  }

  void _updatePhraseControllers() {
    setState(() {
      textControllers = List.generate(
        categoryPhrases[selectedCategory]!.length,
            (index) => TextEditingController(
          text: categoryPhrases[selectedCategory]![index],
        ),
      );
    });
  }

  Future<void> _setFemaleVoice() async {
    await flutterTts.setLanguage("pl-PL");
    await flutterTts.setVoice({"name": "pl-pl-x-oda-network", "locale": "pl-PL"});
    await flutterTts.setSpeechRate(0.8);
  }

  void _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _changeCategory(String category) {
    setState(() {
      selectedCategory = category;
      categoryNameController.text = category;
      _updatePhraseControllers();
    });
  }

  void _renameCategory(String newName) {
    if (newName.isEmpty || categoryPhrases.containsKey(newName)) return;

    setState(() {
      categoryPhrases[newName] = categoryPhrases.remove(selectedCategory)!;
      selectedCategory = newName;
      _savePhrases();
    });
  }

  void _updatePhrase(int index, String text) {
    setState(() {
      categoryPhrases[selectedCategory]![index] = text;
      _savePhrases();
    });
  }

  void _addPhrase() {
    setState(() {
      categoryPhrases[selectedCategory]!.add("Nowe zdanie");
      textControllers.add(TextEditingController(text: "Nowe zdanie"));
      _savePhrases();
    });
  }

  void _deletePhrase(int index) {
    setState(() {
      categoryPhrases[selectedCategory]!.removeAt(index);
      textControllers.removeAt(index);
      _savePhrases();
    });
  }

  void _addCategory() {
    setState(() {
      String newCategory = "Nowa zakładka ${categoryPhrases.length}";
      categoryPhrases[newCategory] = [];
      _changeCategory(newCategory);
      _savePhrases();
    });
  }

  void _deleteCategory() {
    if (selectedCategory == "Główne") return; // Don't delete the main category
    setState(() {
      categoryPhrases.remove(selectedCategory);
      selectedCategory = "Główne";
      categoryNameController.text = "Główne";
      _updatePhraseControllers();
      _savePhrases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mowa PLS'), actions: [
        PopupMenuButton<String>(
          icon: Icon(Icons.menu),
          itemBuilder: (BuildContext context) {
            return [
              ...categoryPhrases.keys.map((String category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              PopupMenuItem<String>(
                value: "add_category",
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Dodaj zakładkę"),
                  ],
                ),
              ),
            ];
          },
          onSelected: (value) {
            if (value == "add_category") {
              _addCategory();
            } else {
              _changeCategory(value);
            }
          },
        ),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Editable zakładka name
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: categoryNameController,
                      decoration: InputDecoration(
                        labelText: "Nazwa zakładki",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _renameCategory,
                    ),
                  ),
                  if (selectedCategory != "Główne") // Prevent deleting the main category
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteCategory,
                    ),
                ],
              ),
              SizedBox(height: 20),
              // Phrases list
              ...List.generate(textControllers.length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textControllers[i],
                          decoration: InputDecoration(
                            labelText: "Edytuj zdanie",
                            border: OutlineInputBorder(),
                          ),
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.start,
                          onChanged: (value) => _updatePhrase(i, value),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.play_arrow),
                        onPressed: () => _speak(textControllers[i].text),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deletePhrase(i),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addPhrase,
                icon: Icon(Icons.add),
                label: Text("Dodaj nowe zdanie"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
