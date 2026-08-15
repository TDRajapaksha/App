import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/supabase_service.dart';
import 'user_session.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General';
  String _selectedPriority = 'medium';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Order Issue',
    'Payment',
    'Shipping',
    'Product',
    'Account',
    'Other',
    'Technical',
  ];

  final List<String> _priorities = ['low', 'medium', 'high', 'urgent'];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I place an order?',
      'answer':
          'Simply browse our collection, add items to your cart, and proceed to checkout. You\'ll need to log in and provide a shipping address.',
    },
    {
      'question': 'What payment methods do you accept?',
      'answer':
          'We accept credit/debit cards, mobile wallets, and bank transfers. All payments are processed securely.',
    },
    {
      'question': 'How long does shipping take?',
      'answer':
          'Standard shipping takes 3-5 business days. Express shipping is available for 1-2 business days.',
    },
    {
      'question': 'Can I cancel my order?',
      'answer':
          'Orders can be canceled within 2 hours of placing them. Contact our support team immediately for cancellation requests.',
    },
    {
      'question': 'Do you offer returns?',
      'answer':
          'Yes, we offer a 7-day return policy for unused items in their original packaging. Contact us for return instructions.',
    },
  ];

  Future<void> _submitTicket() async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _supabaseService.submitSupportTicket(
        subject: _subjectController.text,
        message: _messageController.text,
        category: _selectedCategory,
        priority: _selectedPriority,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Support ticket submitted! We\'ll get back to you soon.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedCategory = 'General';
        _selectedPriority = 'medium';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri callUri = Uri(scheme: 'tel', path: '+1234567890');
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not make phone call'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@metalart.com',
      query: 'subject=Support Request&body=Hello, I need help with...',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          backgroundColor: const Color(0xFF004C99),
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Help & Support',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'FAQs'),
              Tab(text: 'Contact'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(children: [_buildFAQTab(), _buildContactTab()]),
      ),
    );
  }

  Widget _buildFAQTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqs.length,
      itemBuilder: (context, index) {
        final faq = _faqs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            title: Text(
              faq['question']!,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq['answer']!,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Quick Contact Options
          Row(
            children: [
              Expanded(
                child: _buildQuickContactCard(
                  icon: Icons.phone_in_talk,
                  label: 'Call Us',
                  subtitle: '24/7 Support',
                  color: Colors.green,
                  onTap: _makePhoneCall,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickContactCard(
                  icon: Icons.email_outlined,
                  label: 'Email Us',
                  subtitle: 'support@metalart.com',
                  color: Colors.blue,
                  onTap: _sendEmail,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Contact Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Send a Message',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _priorities.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPriority = value!);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messageController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitTicket,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004C99),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Submit Ticket',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Response Time
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF004C99).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF004C99).withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: const Color(0xFF004C99)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We typically respond within 24 hours during business days.',
                    style: TextStyle(
                      color: const Color(0xFF004C99),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickContactCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
