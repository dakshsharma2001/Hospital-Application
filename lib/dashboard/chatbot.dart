import 'package:flutter/material.dart';

class AIChatbotScreen extends StatefulWidget {
  @override
  _AIChatbotScreenState createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  void _handleSubmitted(String text) {
    _textController.clear();
    ChatMessage message = ChatMessage(
      text: text,
      isUser: true,
    );
    setState(() {
      _messages.insert(0, message);
    });
    _getBotResponse(text);
  }

  void _getBotResponse(String query) {
    // This is where you'd integrate with the Gemini API
    // For now, we'll use a simple predefined response system
    String response = _getSimpleResponse(query);
    ChatMessage botMessage = ChatMessage(
      text: response,
      isUser: false,
    );
    setState(() {
      _messages.insert(0, botMessage);
    });
  }

  String _getSimpleResponse(String query) {
    query = query.toLowerCase();

    // List of keywords for each category
    final appointmentKeywords = ['appointment', 'book', 'schedule', 'reserve'];
    final emergencyKeywords = ['emergency', 'urgent', 'critical'];
    final departmentKeywords = ['department', 'ward', 'unit', 'section'];
    final doctorKeywords = [
      'doctor',
      'physician',
      'specialist',
      'practitioner'
    ];
    final contactKeywords = ['contact', 'connect', 'call', 'message'];
    final locationKeywords = [
      'location',
      'place',
      'destination',
      'Hospital location'
    ];

    // Check for appointment-related queries
    if (appointmentKeywords.any((keyword) => query.contains(keyword))) {
      return "To make an appointment, please tap on the plus icon on the map. There you will see a 'Take Appointment' option.";
    }

    // Check for emergency-related queries
    if (emergencyKeywords.any((keyword) => query.contains(keyword))) {
      return "For emergencies, please call 911 immediately or go to the nearest hospital's emergency room.";
    }

    // Check for department-related queries
    if (departmentKeywords.any((keyword) => query.contains(keyword))) {
      return "You can view the departments of each hospital by tapping on the hospital marker on the map.";
    }
    if (contactKeywords.any((keyword) => query.contains(keyword))) {
      return "You can contact you appointed doctor. We have sent you the email of your appointment. There you have the doctor contact number.";
    }
    if (locationKeywords.any((keyword) => query.contains(keyword))) {
      return "Location! Please give the location access to the app. Then you can see nearby hospitals.";
    }

    // Check for doctor-related queries
    if (doctorKeywords.any((keyword) => query.contains(keyword))) {
      return "Department of doctor you want to see can be seen when you select the doctor in appointment screen.";
    }

    // If no specific category is detected, provide a general response
    return "I'm sorry, I couldn't understand your query. Could you please rephrase your question about our hospital management system? You can ask about appointments, emergencies, departments, or doctors.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ' Assistant',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        decoration: BoxDecoration(color: Colors.white),
        margin: EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration:
                    InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: Colors.blue,
                ),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(isUser ? "You" : "Bot")),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isUser ? "You" : " Assistant",
                    style: TextStyle(color: Colors.grey)),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
