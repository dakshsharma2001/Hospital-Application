import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  PrescriptionDetailsScreen({
    required this.patientId,
    required this.patientName,
  });

  @override
  _PrescriptionDetailsScreenState createState() =>
      _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  final _supabase = Supabase.instance.client;
  late Future<Map<String, dynamic>> _prescriptionFuture;
  double totalPrice = 0.0; // State variable for total price
  String patientEmail = ''; // State variable for patient email
  bool _isLoading = false; // State variable for loading state
  bool billPaid = false; // State variable for bill payment status

  @override
  void initState() {
    super.initState();
    _prescriptionFuture = _fetchPrescriptionDetails();
  }

  Future<Map<String, dynamic>> _fetchPrescriptionDetails() async {
    try {
      // Fetch prescription
      final prescriptionResponse = await _supabase
          .from('prescriptions')
          .select('prescription, medicines')
          .eq('patientId', widget.patientId)
          .single();

      // Fetch medicine details
      final medicineIds = (prescriptionResponse['medicines'] as List)
          .map((e) => e.toString())
          .toList();
      final medicineResponse = await _supabase
          .from('medicinesinventory')
          .select('id, name, price')
          .inFilter('id', medicineIds);

      // Fetch patient email and bill payment status
      final patientResponse = await _supabase
          .from('patients')
          .select('email, billpayed')
          .eq('id', widget.patientId)
          .single();
      patientEmail = patientResponse['email']; // Store patient email
      billPaid =
          patientResponse['billpayed'] ?? false; // Store bill payment status

      // Calculate total price of medicines
      double tempTotalPrice = 0.0; // Local variable to calculate total price
      for (var medicine in medicineResponse) {
        tempTotalPrice += (medicine['price'] ?? 0.0);
      }
      totalPrice = tempTotalPrice; // Update state variable

      // Fetch doctor fee based on patientId
      final doctorResponse = await _supabase
          .from('doctor')
          .select('fee, patientappointId')
          .contains('patientappointId', [widget.patientId]).single();

      final doctorFee = doctorResponse['fee'] ?? 0.0; // Get doctor's fee
      totalPrice += doctorFee; // Add doctor's fee to total price

      return {
        'prescription': prescriptionResponse['prescription'],
        'medicines': medicineResponse,
        'doctorFee': doctorFee, // Include doctor fee in returned data
      };
    } catch (e) {
      print('Error fetching prescription details: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  void _sendInvoice() async {
    setState(() {
      _isLoading = true; // Set loading state to true
    });

    final medicines = await _fetchMedicines();
    final prescriptionData =
        await _prescriptionFuture; // Fetch prescription data
    String prescription = prescriptionData['prescription'] ??
        'No prescription available'; // Get prescription text

    String invoiceContent = "Hi, ${widget.patientName}\n\n"
        "This is the medicine bill which is due. You need to pay this before the 7 days end.\n\n"
        "Invoice for ${widget.patientName}\n\n"
        "Your Prescription: $prescription\n\n";

    for (var medicine in medicines) {
      invoiceContent +=
          "Medicine: ${medicine['name']}, Price: ₹${medicine['price']?.toStringAsFixed(2)}\n"
          "*include doctor fees";
    }
    invoiceContent += "\nTotal Price: ₹${totalPrice.toStringAsFixed(2)}";

    final smtpServer = gmail('gsarvesh387@gmail.com',
        'egfripivxkflstod'); // Replace with your email and password
    final message = Message()
      ..from = Address('gsarvesh387@gmail.com') // Replace with your email
      ..recipients.add(patientEmail)
      ..subject = 'Invoice for Your Prescription'
      ..text = invoiceContent;

    try {
      await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill Detail sent to $patientEmail')),
      );
    } catch (e) {
      print('Error sending invoice: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invoice')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMedicines() async {
    final prescriptionData = await _prescriptionFuture;
    return List<Map<String, dynamic>>.from(prescriptionData['medicines']);
  }

  void _showTotalPrice(double totalPrice) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total Price',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              SizedBox(height: 8),
              Text(
                '₹${totalPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 8),
              const Text(
                'Note: Total price includes the doctor’s fee.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Prescription - ${widget.patientName}'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _prescriptionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
              color: Colors.blue,
            ));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final data = snapshot.data!;

            if (data.containsKey('error')) {
              return Center(child: Text('Error: ${data['error']}'));
            }

            final prescription = data['prescription'] as String?;
            final medicines =
                List<Map<String, dynamic>>.from(data['medicines']);

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prescription:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(prescription ?? 'No prescription available'),
                  SizedBox(height: 16),
                  Text('Medicines:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Text(medicine['name'] ?? 'Unknown Medicine'),
                          subtitle:
                              Text('Price: ₹${medicine['price'] ?? 'N/A'}'),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    height: 60,
                  ),
                  GestureDetector(
                    onTap: billPaid
                        ? null
                        : _sendInvoice, // Disable on tap if bill is paid
                    child: Container(
                      height: screenSize.height * 0.07,
                      width: screenSize.width * 0.9,
                      alignment: Alignment.center,
                      child: _isLoading
                          ? CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              billPaid ? "Bill Paid" : "Send Bills",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18),
                            ),
                      decoration: BoxDecoration(
                        color: billPaid
                            ? Colors.grey
                            : Colors
                                .blue, // Change color based on payment status
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showTotalPrice(totalPrice),
        child: Icon(
          Icons.medical_information,
          color: Colors.white,
        ),
      ),
    );
  }
}
